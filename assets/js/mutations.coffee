errors = require './errors.coffee'

###
mutations mutate a document within a session, and are undoable
each mutation should implement a constructor, as well as the following methods:

    str: () -> string
        prints itself
    mutate: (session) -> void
        takes a session and acts on it (mutates the session)
    rewind: (session) -> void
        takes a session, assumed be in the state right after the mutation was applied,
        and returns a list of mutations for undoing it

the mutation may also optionally implement

    validate: (session) -> bool
        returns whether this action is valid at the time (i.e. whether it is okay to call mutate)
    remutate: (session) -> void
        takes a session, and acts on it.  assumes that mutate has been called once already
        by default, remutate is the same as mutate.
        it should be implemented only if it is more efficient than the mutate implementation
    moveCursor: (cursor) -> void
        takes a cursor, and moves it according to how the cursor should move
###

_ = require 'lodash'
errors = require './errors.coffee'

# validate inserting id as a child of parent_id
validateRowInsertion = (session, parent_id, id, options={}) ->
  # check that there won't be doubled siblings
  if not options.noSiblingCheck
    if session.document._hasChild parent_id, id
      session.showMessage "Cloned rows cannot be inserted as siblings", {text_class: 'error'}
      return false

  # check that there are no cycles
  # Precondition: tree is not already circular
  # It is sufficient to check if the row is an ancestor of the new parent,
  # because if there was a clone underneath the row which was an ancestor of 'parent',
  # then 'row' would also be an ancestor of 'parent'.
  if _.includes (session.document.allAncestors parent_id, { inclusive: true }), id
    session.showMessage "Cloned rows cannot be nested under themselves", {text_class: 'error'}
    return false
  return true

class Mutation
  str: () ->
    return ''
  validate: (session) ->
    return true
  mutate: (session) ->
    return
  rewind: (session) ->
    return []
  remutate: (session) ->
    return @mutate session
  moveCursor: (cursor) ->
    return

class AddChars extends Mutation
  constructor: (@row, @col, @chars) ->

  str: () ->
    return "row #{@row}, col #{@col}, nchars #{@chars.length}"

  mutate: (session) ->
    session.document.writeChars @row, @col, @chars

  rewind: (session) ->
    return [
      new DelChars @row, @col, @chars.length
    ]

  moveCursor: (cursor) ->
    if not (cursor.path.row == @row)
      return
    if cursor.col >= @col
      cursor.setCol (cursor.col + @chars.length)

class DelChars extends Mutation
  constructor: (@row, @col, @nchars) ->

  str: () ->
    return "row #{@row}, col #{@col}, nchars #{@nchars}"

  mutate: (session) ->
    @deletedChars = session.document.deleteChars @row, @col, @nchars

  rewind: (session) ->
    return [
      new AddChars @row, @col, @deletedChars
    ]

  moveCursor: (cursor) ->
    if cursor.row != @row
      return
    if cursor.col < @col
      return
    else if cursor.col < @col + @nchars
      cursor.setCol(@col)
    else
      cursor.setCol((cursor.col - @nchars))

class ChangeChars extends Mutation
  constructor: (@row, @col, @nchars, @transform, @newChars) ->

  str: () ->
    return "change row #{@row}, col #{@col}, nchars #{@nchars}"

  mutate: (session) ->
    @deletedChars = session.document.deleteChars @row, @col, @nchars
    @ncharsDeleted = @deletedChars.length
    if @transform
      @newChars = @transform @deletedChars
      errors.assert (@newChars.length == @ncharsDeleted)
    session.document.writeChars @row, @col, @newChars

  rewind: (session) ->
    return [
      new ChangeChars @row, @col, @newChars.length, null, @deletedChars
    ]

  remutate: (session) ->
    session.document.deleteChars @row, @col, @ncharsDeleted
    session.document.writeChars @row, @col, @newChars

  # doesn't move cursors

class MoveBlock extends Mutation
  constructor: (@path, @parent, index) ->
    @old_parent = @path.parent
    if index == undefined
      @index = -1
    else
      @index = index

  str: () ->
    return "move #{@path.row} from #{@path.parent.row} to #{@parent.row}"

  validate: (session) ->
    # if parent is the same, don't do sibling clone validation
    sameParent = @parent.row == @old_parent.row
    return (validateRowInsertion session, @parent.row, @path.row, {noSiblingCheck: sameParent})

  mutate: (session) ->
    errors.assert (not do @path.isRoot), "Cannot detach root"
    info = session.document._move @path.row, @old_parent.row, @parent.row, @index
    @old_index = info.old.childIndex

  rewind: (session) ->
    return [
      new MoveBlock (@parent.extend [@path.row]), @old_parent, @old_index
    ]

  moveCursor: (cursor) ->
    walk = cursor.path.walkFrom @path
    if walk == null
      return
    # TODO: other cursors could also
    # be on a relevant path..
    cursor._setPath (@parent.extend [@path.row]).extend walk

class AttachBlocks extends Mutation
  constructor: (@parent, @cloned_rows, index, options) ->
    @nrows = @cloned_rows.length
    if index == undefined
      @index = -1
    else
      @index = index
    @options = options || {}

  str: () ->
    return "parent #{@parent}, index #{@index}"

  validate: (session) ->
    for row in @cloned_rows
      if not (validateRowInsertion session, @parent, row)
        return false
    return true

  mutate: (session) ->
    session.document._attachChildren @parent, @cloned_rows, @index

  rewind: (session) ->
    return [
      new DetachBlocks @parent, @index, @nrows
    ]

class DetachBlocks extends Mutation
  constructor: (@parent, @index, nrows, options) ->
    @nrows = nrows or 1
    @options = options || {}

  str: () ->
    return "parent #{@parent}, index #{@index}, nrows #{@nrows}"

  mutate: (session) ->
    @deleted = (session.document._getChildren @parent, @index, (@index+@nrows-1)).filter ((sib) -> sib != null)

    for row in @deleted
      session.document._detach row, @parent

    @created = null
    if @options.addNew
      @created = session.document._newChild(@parent, @index)
      @created_index = session.document._childIndex(@parent, @created)

    children = session.document._getChildren @parent

    # note: next is a path, relative to the parent

    if @index < children.length
      next = [children[@index]]
    else
      if @index == 0
        next = []
        if @parent == session.document.root.row
          unless @options.noNew
            @created = session.document._newChild(@parent)
            @created_index = session.document._childIndex(@parent, @created)
            next = [@created]
      else
        child = children[@index - 1]
        walk = session.document.walkToLastVisible(child)
        next = [child].concat(walk)

    @next = next

  rewind: (session) ->
    mutations = []
    if @created != null
      mutations.push new DetachBlocks @parent, @created_index, 1, {noNew: true}
    mutations.push new AttachBlocks @parent, @deleted, @index
    return mutations

  remutate: (session) ->
    for row in @deleted
      session.document._detach row, @parent
    if @created != null
      session.document._attach @created, @parent, @created_index

  moveCursor: (cursor) ->
    [walk, ancestor] = cursor.path.shedUntil @parent
    if walk == null
      return
    if walk.length == 0
      return
    child = walk[0]
    if (@deleted.indexOf child) == -1
      return
    cursor.set (ancestor.extend @next), 0

# creates new blocks (as opposed to attaching ones that already exist)
class AddBlocks extends Mutation
  constructor: (@parent, index, @serialized_rows) ->
    if index == undefined
      @index = -1
    else
      @index = index
    @nrows = @serialized_rows.length

  str: () ->
    return "parent #{@parent.row}, index #{@index}"

  mutate: (session) ->
    index = @index

    first = true
    id_mapping = {}
    @added_rows = []
    for serialized_row in @serialized_rows
      row = session.document.loadTo serialized_row, @parent, index, id_mapping
      @added_rows.push row
      index += 1
    return null

  rewind: (session) ->
    return [
      new DetachBlocks @parent.row, @index, @nrows
    ]

  remutate: (session) ->
    index = @index
    for sib in @added_rows
      session.document.attachChild @parent, sib, index
      index += 1
    return null

class ToggleBlock extends Mutation
  constructor: (@row) ->
  str: () ->
    return "row #{@row}"
  mutate: (session) ->
    session.document.toggleCollapsed @row
  rewind: (session) ->
    return [
      @
    ]

  # TODO: if a cursor is within the toggle block and their
  # viewRoot isn't, do a moveCursor?

exports.Mutation = Mutation

exports.AddChars = AddChars
exports.DelChars = DelChars
exports.ChangeChars = ChangeChars
exports.AddBlocks = AddBlocks
exports.DetachBlocks = DetachBlocks
exports.AttachBlocks = AttachBlocks
exports.MoveBlock = MoveBlock
exports.ToggleBlock = ToggleBlock

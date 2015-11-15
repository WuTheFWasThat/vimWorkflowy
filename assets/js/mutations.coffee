###
mutations mutate the data of a view, and are undoable
each mutation should implement a constructor, as well as the following methods:

    str: () -> string
        prints itself
    mutate: (view) -> void
        takes a view and acts on it (mutates the view)
    rewind: (view) -> void
        takes a view, assumed be in the state right after the mutation was applied, and undoes the mutation

the mutation may also optionally implement

    remutate: (view) -> void
        takes a view, and acts on it.  assumes that mutate has been called once already
        by default, remutate is the same as mutate.
        it should be implemented only if it is more efficient than the mutate implementation
###

if module?
  global.errors = require('./errors.coffee')

((exports) ->
  class Mutation
    str: () ->
      return ''
    mutate: (view) ->
      return
    rewind: (view) ->
      return
    remutate: (view) ->
      return @mutate view

  class AddChars extends Mutation
    # options:
    #   setCursor: if you wish to set the cursor, set to 'beginning' or 'end'
    #              indicating where the cursor should go to

    constructor: (@row, @col, @chars, @options = {}) ->
      @options.setCursor ?= 'end'
      @options.cursor ?= {}

    str: () ->
      return "row #{@row.id}, col #{@col}, nchars #{@chars.length}"

    mutate: (view) ->
      view.data.writeChars @row, @col, @chars

      shift = if @options.cursor.pastEnd then 1 else 0
      if @options.setCursor == 'beginning'
        view.cursor.set @row, (@col + shift), @options.cursor
      else if @options.setCursor == 'end'
        view.cursor.set @row, (@col + shift + @chars.length - 1), @options.cursor

    rewind: (view) ->
      view.data.deleteChars @row, @col, @chars.length

  class DelChars extends Mutation
    constructor: (@row, @col, @nchars, @options = {}) ->
      @options.setCursor ?= 'before'
      @options.cursor ?= {}

    str: () ->
      return "row #{@row.id}, col #{@col}, nchars #{@nchars}"

    mutate: (view) ->
      @deletedChars = view.data.deleteChars @row, @col, @nchars
      if @options.setCursor == 'before'
        view.cursor.set @row, @col, @options.cursor
      else if @options.setCursor == 'after'
        view.cursor.set @row, (@col + 1), @options.cursor

    rewind: (view) ->
      view.data.writeChars @row, @col, @deletedChars

  class InsertRow extends Mutation
    constructor: (@parent, @index) ->

    str: () ->
      return "parent #{@parent.id} index #{@index}"

    mutate: (view) ->
      @newrow = view.data.addChild @parent, @index
      view.cursor.set @newrow, 0

    rewind: (view) ->
      @rewinded = view.data.detach @newrow

    remutate: (view) ->
      view.data.attachChild @parent, @newrow, @index

  class DetachBlock extends Mutation
    constructor: (@row, @options = {}) ->

    str: () ->
      return "row #{@row.id}"

    mutate: (view) ->
      errors.assert_not_equals @row.id, view.data.root.id, "Cannot detach root"
      @detached = view.data.detach @row

    rewind: (view) ->
      view.data.attachChild @detached.parent, @row, @detached.index

  class AttachBlock extends Mutation
    constructor: (@row, @parent, @index = -1, @options = {}) ->

    str: () ->
      return "row #{@row.id}, parent #{@parent}"

    mutate: (view) ->
      view.data.attachChild @parent, @row, @index

    rewind: (view) ->
      view.data.detach @row

  class DeleteBlocks extends Mutation
    constructor: (@parent, @index, @nrows = 1, @options = {}) ->

    str: () ->
      return "parent #{@parent.id}, index #{@index}, nrows #{@nrows}"

    mutate: (view) ->
      @deleted_rows = []
      delete_rows = view.data.getChildRange @parent, @index, (@index+@nrows-1)
      for sib in delete_rows
        if sib == null then break
        @deleted_rows.push sib
        view.data.detach sib

      @created = null
      if @options.addNew
        @created = view.data.addChild @parent, @index

      children = view.data.getChildren @parent

      if @index < children.length
        next = children[@index]
      else
        next = if @index == 0 then @parent else children[@index - 1]
        if next.id == view.data.viewRoot.id
          next = view.data.addChild @parent
          @created = next

      view.cursor.set next, 0

    rewind: (view) ->
      if @created != null
        @created_rewinded = view.data.detach @created
      index = @index
      for row in @deleted_rows
        view.data.attachChild @parent, row, index
        index += 1

    remutate: (view) ->
      for row in @deleted_rows
        view.data.detach row
      if @created != null
        view.data.attachChild @created_rewinded.parent, @created, @created_rewinded.index

  class AddBlocks extends Mutation
    # options:
    #   setCursor: if you wish to set the cursor, set to 'first' or 'last',
    #              indicating which block the cursor should go to

    constructor: (@serialized_rows, @parent, @index = -1, @options = {}) ->
      @nrows = @serialized_rows.length

    str: () ->
      return "parent #{@parent.id}, index #{@index}"

    mutate: (view) ->
      index = @index

      first = true
      for serialized_row in @serialized_rows
        row = view.data.loadTo serialized_row, @parent, index
        index += 1

        if @options.setCursor == 'first' and first
          view.cursor.set row, 0
          first = false

      if @options.setCursor == 'last'
        view.cursor.set row, 0

    rewind: (view) ->
      @delete_siblings = view.data.getChildRange @parent, @index, (@index + @nrows - 1)
      for sib in @delete_siblings
        view.data.detach sib

    remutate: (view) ->
      index = @index
      for sib in @delete_siblings
        view.data.attachChild @parent, sib, index
        index += 1

  class CloneBlocks extends Mutation
    # options:
    #   setCursor: if you wish to set the cursor, set to 'first' or 'last',
    #              indicating which block the cursor should go to

    constructor: (@cloned_rows, @parent, @index = -1, @options = {}) ->
      @nrows = @cloned_rows.length

    str: () ->
      return "parent #{@parent.id}, index #{@index}"

    _checkSibling: (view) ->
      children = view.data.getChildren @parent
      for clone_id in @cloned_rows
        if _.find children, { id: clone_id }
          return false
      return true

    checkCircular: (view) ->
      @_checkCircularTree view, _.map(@cloned_rows, (clone_id) -> view.data.canonicalInstance clone_id)

    _checkCircularTree: (view, rows) ->
      for row in rows
        if view.data.wouldBeCircularInsert row, @parent
          return false
        unless @_checkCircularTree view, (view.data.getChildren row)
          return false
      return true

    mutate: (view) ->
      unless (@_checkSibling view)
        return view.showMessage "Cloned rows cannot be inserted as siblings", {text_class: 'error'}
      unless (@checkCircular view)
        return view.showMessage "Cloned rows cannot be nested under themselves", {text_class: 'error'}

      index = @index

      first = true
      for clone_id in @cloned_rows
        original = view.data.canonicalInstance clone_id
        unless original?
          continue
        try
          clone = view.data.cloneRow original, @parent, index
          index += 1
        catch error
          unless error instanceof errors.CircularReference
            throw error
          return view.showMessage "Rows cannot be nested under themselves", {text_class: 'error'}

        if @options.setCursor == 'first' and first
          view.cursor.set clone, 0
          first = false

      if @options.setCursor == 'last' and row?
        view.cursor.set clone, 0

    rewind: (view) ->
      delete_siblings = view.data.getChildRange @parent, @index, (@index + @nrows - 1)
      for sib in delete_siblings
        view.data.detach sib

  class ToggleBlock extends Mutation
    constructor: (@row) ->
    str: () ->
      return "row #{@row.id}"
    mutate: (view) ->
      view.data.toggleCollapsed @row
    rewind: (view) ->
      view.data.toggleCollapsed @row

  class SetMark extends Mutation
    constructor: (@row, @mark) ->
    str: () ->
      return "row #{@row.id}, mark #{@mark}"
    mutate: (view) ->
      @oldmark = view.data.getMark @row
      view.data.setMark @row, @mark
    rewind: (view) ->
      view.data.setMark @row, @oldmark

  exports.AddChars = AddChars
  exports.DelChars = DelChars
  exports.InsertRow = InsertRow
  exports.DetachBlock = DetachBlock
  exports.AttachBlock = AttachBlock
  exports.DeleteBlocks = DeleteBlocks
  exports.AddBlocks = AddBlocks
  exports.CloneBlocks = CloneBlocks
  exports.ToggleBlock = ToggleBlock
  exports.SetMark = SetMark
)(if typeof exports isnt 'undefined' then exports else window.mutations = {})

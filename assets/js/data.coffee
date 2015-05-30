class Data
  root: 0

  constructor: () ->
    # defaults

    # default document: a single blank line
    @viewRoot = 0

    @load {
      line: ''
      children: ['']
    }
    return @

  changeViewRoot: (row) ->
    @viewRoot = row

  getId: () ->
    id = 0
    while @lines[id]
      id++
    return id

  # data access

  getLine: (row) ->
    return @lines[row]

  setLine: (row, line) ->
    @lines[row] = line

  getChar: (row, col) ->
    return @getLine(row)[col]

  getLength: (row) ->
    return @getLine(row).length

  getParent: (row) ->
    return @structure[row].parent

  setParent: (row, parent) ->
    @structure[row].parent = parent

  getChildren: (row) ->
    return @structure[row].children

  hasChildren: (row) ->
    return (@structure[row].children.length > 0)

  getSiblings: (row) ->
    parent = @getParent row
    return @getChildren parent

  collapsed: (row) ->
    return @structure[row].collapsed

  setCollapsed: (row, collapsed) ->
    @structure[row].collapsed = collapsed

  # structure manipulation

  indexOf: (child) ->
    children = @getSiblings child
    return children.indexOf child

  detach: (id) ->
    parent = @getParent id
    index = @detachChild parent, id
    return {
      parent: parent
      index: index
    }

  detachChild: (id, child) ->
    children = @getChildren id
    i = children.indexOf child
    children.splice i, 1
    return i

  attachChild: (id, child, index = -1) ->
    @attachChildren id, [child], index

  attachChildren: (id, new_children, index = -1) ->
    children = @getChildren id
    if index == -1
      children.push.apply children, new_children
    else
      children.splice.apply children, [index, 0].concat(new_children)
    for child in new_children
      @setParent child, id

  nextVisible: (id = @viewRoot) ->
    if not @collapsed id
      children = @getChildren id
      if children.length > 0
        return children[0]
    while true
      nextsib = @getSiblingAfter id
      if nextsib != null
        return nextsib
      id = @getParent id
      if id == @viewRoot
        return null

  # last thing visible nested within id
  lastVisible: (id = @viewRoot) ->
    if @collapsed id
      return id
    children = @getChildren id
    if children.length > 0
      return @lastVisible children[children.length - 1]
    return id

  prevVisible: (id) ->
    prevsib = @getSiblingBefore id
    if prevsib != null
      return @lastVisible prevsib
    parent = @getParent id
    if parent == @viewRoot
      return null
    return parent

  toggleCollapsed: (id) ->
    @setCollapsed id, (not @collapsed id)

  getSiblingBefore: (id) ->
    return @getSiblingOffset id, -1

  getSiblingAfter: (id) ->
    return @getSiblingOffset id, 1

  getSiblingOffset: (id, offset) ->
    return (@getSiblingRange id, offset, offset)[0]

  getSiblingRange: (id, min_offset, max_offset) ->
    children = @getSiblings id
    index = @indexOf id
    return @getChildRange (@getParent id), (min_offset + index), (max_offset + index)

  getChildRange: (id, min, max) ->
    children = @getChildren id
    indices = [min..max]

    return indices.map (index) ->
      if index >= children.length
        return null
      else if index < 0
        return null
      else
        return children[index]

  addChild: (id, index = -1) ->
    child = do @getId

    @lines[child] = []
    @structure[child] =
      collapsed: false
      children: []
      parent: id

    @attachChild id, child, index

    return child

  # this is never used, since data structure is basically persistent
  # deleteRow: (id) ->
  #   if id == @viewRoot
  #     throw 'Cannot delete view root'

  #   for child in (@getChildren id).slice()
  #     @deleteRow child

  #   @detach id
  #   delete @structure[id]
  #   delete @lines[id]

  _insertSiblingHelper: (id, after) ->
    if id == @viewRoot
      console.log 'Cannot insert sibling of view root'
      return null

    newId = do @getId
    parent = @getParent id
    children = @getChildren parent
    index = children.indexOf id

    return (@addChild parent, (index + after))

  insertSiblingAfter: (id) ->
    return @_insertSiblingHelper id, 1

  insertSiblingBefore: (id) ->
    return @_insertSiblingHelper id, 0

  # data manipulation

  writeChars: (row, col, chars) ->
    args = [col, 0].concat chars
    [].splice.apply @lines[row], args

  deleteChars: (row, col, num) ->
    removed = @lines[row].splice col, num
    return removed

  orderedLines: () ->
    ids = []

    helper = (id) =>
      ids.push id
      for child in @getChildren id
        helper child
    helper @root
    return ids

  find: (chars) ->
    results = [] # list of (row_id, index) pairs
    if chars.length == 0
      return results

    for id in do @orderedLines
      line = @lines[id]
      for i in [0..line.length-chars.length]
        match = true
        for j in [0...chars.length]
          if line[i+j] != chars[j]
            match = false
            break
        if match
          results.push {
            row: id
            index: i
          }
          break
    return results

  # important: serialized automatically garbage collects
  serialize: (id = @root) ->
    line = @lines[id].join('')
    if @structure[id].children.length
      children = (@serialize childid for childid in @getChildren id)
      struct = {
        line: line
        children: children
      }
      if id == @root and @viewRoot != @root
        struct.viewRoot = @viewRoot
      if @collapsed id
        struct.collapsed = true
      return struct
    else
      return line

  loadTo: (serialized, parent = @root, index = -1) ->
    id = do @getId

    @structure[id] = {
      children: []
    }

    if id != @root
      @attachChild parent, id, index
    else
      # parent should be 0
      @structure[id].parent = @root

    if typeof serialized == 'string'
      @setLine id, (serialized.split '')
    else
      @setLine id, (serialized.line.split '')
      @setCollapsed id, serialized.collapsed

      for serialized_child in serialized.children
        @loadTo serialized_child, id

    return id

  load: (serialized) ->
    @structure = {}
    @lines = {}
    if serialized.viewRoot
      @viewRoot = serialized.viewRoot
    else
      @viewRoot = @root

    @loadTo serialized

# exports
module?.exports = Data

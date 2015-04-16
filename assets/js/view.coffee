# a View consists of Data and a cursor
# it also renders

class View
  constructor: (mainDiv, data) ->
    @mainDiv = mainDiv
    @data = data

    @curRow = 1 # id
    @curCol = 0

    @history = []
    @historyIndex = 0

    return @

  # ACTIONS

  add_history: (action) ->
    # TODO: check if we can merge with previous action
    if @historyIndex != @history.length
        @history = @history.slice 0, @historyIndex
    @history.push action
    @historyIndex += 1

  undo: () ->
    if @historyIndex > 0
      @historyIndex -= 1
      action = @history[@historyIndex]
      action.rewind @
      [@curRow, @curCol] = action.oldCursor
      @setCur @curRow, @curCol
      @drawRow @curRow

  redo: () ->
    if @historyIndex < @history.length
      action = @history[@historyIndex]
      action.apply @
      @historyIndex += 1

  act: (action) ->
    action.oldCursor = [@curRow, @curCol]
    action.apply @
    @add_history action

  # CURSOR MOVEMENT AND DATA MANIPULATION

  setCur: (row, col, options) ->
    options ?= {}
    @curRow = row
    @curCol = col

    shift = if options.pastEnd then 0 else 1
    if @curCol > @data.lines[@curRow].length - shift
      @curCol = @data.lines[@curRow].length - shift

  moveCursorBackIfNeeded: () ->
    if @curCol > @data.lines[@curRow].length - 1
      do @moveCursorLeft

  cursorLeft: () ->
    col = @curCol
    if col > 0
      col -= 1
    return [@curRow, col]

  cursorRight: (options) ->
    options?={}
    shift = if options.pastEnd then 0 else 1
    col = @curCol
    if col < @data.lines[@curRow].length - shift
      col += 1
    return [@curRow, col]

  cursorHome: () ->
    return [@curRow, 0]

  cursorEnd: (options) ->
    options ?= {}
    shift = if options.pastEnd then 0 else 1
    return [@curRow, (@data.lines[@curRow].length - shift)]

  moveCursor: (row, col) ->
    oldrow = @curRow
    @curRow = row
    @curCol = col

    @drawRow oldrow
    @drawRow @curRow

  moveCursorEnd: (options) ->
    [row, @curCol] = @cursorEnd options
    @drawRow @curRow

  moveCursorRight: (options) ->
    [row, @curCol] = @cursorRight options
    @drawRow @curRow

  moveCursorLeft: () ->
    [row, @curCol] = do @cursorLeft
    @drawRow @curRow

  moveCursorHome: () ->
    [row, @curCol] = do @cursorHome
    @drawRow @curRow

  # RENDERING

  render: () ->
    @renderHelper @mainDiv, 0

  renderHelper: (onto, rootid) ->
    for id in @data.structure[rootid].children
      do onto.empty
      elId = 'node-' + id
      el = $('<div>').attr('id', elId).addClass('.node')
      elLine = $('<div>').attr 'id', (elId + '-row')

      console.log @data.lines, id, @data.lines[id]
      @drawRow id, elLine

      el.append elLine
      console.log 'elline', elLine
      console.log 'el', el
      console.log 'onto', onto
      onto.append el

  drawRow: (row, onto) ->
    console.log('drawing row', row)
    if not onto
      onto = $('#node-' + row + '-row')
    lineData = @data.lines[row]

    console.log lineData

    line = lineData.map (x) ->
      if x == ' '
        return '&nbsp;'
      return x

    # add cursor
    if row == @curRow and lineData.length == @curCol
      line.push '&nbsp;'

    do onto.empty

    acc = ''
    style = ''
    for x, i in line
      mystyle = ''
      if row == @curRow and i == @curCol
        mystyle = 'cursor'
      if mystyle != style
        onto.append $('<span>').html(acc).addClass(style)
        style = mystyle
        acc = ''
      acc += x

    if acc.length
      onto.append $('<span>').html(acc).addClass(style)

module?.exports = View

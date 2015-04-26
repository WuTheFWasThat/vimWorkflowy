((exports) ->

  # actions mutate the data of a view, and are undoable

  class Action
    apply: (view) ->
      return
    rewind: (view) ->
      return

  class AddChars extends Action
    constructor: (row, col, chars, options = {}) ->
      @row = row
      @col = col
      @chars = chars
      @options = options
    apply: (view) ->
      view.data.writeChars @row, @col, @chars
      view.setCur @row, (@col + @chars.length), @options
      view.drawRow @row
    rewind: (view) ->
      reverse = new DelChars @row, @col, @chars.length
      reverse.apply view

  class DelChars extends Action
    constructor: (row, col, nchars, options = {}) ->
      @row = row
      @col = col
      @nchars = nchars
      @options = options
    apply: (view) ->
      @chars = view.data.deleteChars @row, @col, @nchars
      view.setCur @row, @col, @options
      view.drawRow @row
    rewind: (view) ->
      view.data.writeChars @row, @col, @chars
      view.drawRow @row

  # NOTE: this generalized add/del chars...
  class SpliceChars extends Action
    constructor: (row, col, nchars, chars, options = {}) ->
      @row = row
      @col = col
      @nchars = nchars
      @chars = chars

      options.cursor ?= 'end'
      @options = options

    apply: (view) ->
      @deletedChars = view.data.deleteChars @row, @col, @nchars
      view.data.writeChars @row, @col, @chars

      if @options.cursor == 'beforeEnd'
        view.setCur @row, (@col + @chars.length - 1)
      else if @options.cursor == 'end'
        view.setCur @row, (@col + @chars.length)
      else if @options.cursor == 'pastEnd'
        view.setCur @row, (@col + @chars.length), {pastEnd: true}

      view.drawRow @row

    rewind: (view) ->
      view.data.deleteChars @row, @col, @chars.length
      view.data.writeChars @row, @col, @deletedChars
      view.drawRow @row

  # TODO: make all the `do view.render` more efficient

  class InsertRowSibling extends Action
    constructor: (row, options) ->
      @row = row
      @options = options

    apply: (view) ->
      if @options.after
        @newrow = view.data.insertSiblingAfter @row
      else if @options.before
        @newrow = view.data.insertSiblingBefore @row
      else
        console.log @options
        throw 'InsertRowSibling needs valid option'
      view.setCur @newrow, 0
      do view.render

    rewind: (view) ->
      view.data.deleteRow @newrow
      do view.render

  class DeleteRow extends Action
    constructor: (row) ->
      @row = row

    apply: (view) ->
      # leaves dangling pointers, for both paste and undo
      # these get garbage collected when we serialize/deserialize

      if @row == view.root
        throw 'Cannot delete root'

      parent = view.data.getParent @row

      index = view.data.detachChild parent, @row

      siblings = view.data.getChildren parent
      if index < siblings.length
        next = siblings[index]
      else if index > 0
        next = siblings[index - 1]
      else
        next = parent

      if next == view.data.root
        next = view.data.addChild view.data.root
        @nextCreated = true

      view.setCur next, 0

      @next = next
      @parent = parent
      @index = index

      do view.render

    rewind: (view) ->
      if @nextCreated
        view.data.deleteRow @next
      view.data.attachChild @parent, @row, @index
      do view.render

  class AttachRow extends Action
    constructor: (parent, row, index = -1) ->
      @parent = parent
      @row = row
      @index = index

    apply: (view) ->
      view.data.attachChild @parent, @row, @index
      do view.render

    rewind: (view) ->
      view.data.detach @row
      do view.render

  class DetachRow extends Action
    constructor: (row) ->
      @row = row

    apply: (view) ->
      @result = view.data.detach @row
      do view.render

    rewind: (view) ->
      view.data.attachChild @result.parent, @row, @result.index
      do view.render

  exports.AddChars = AddChars
  exports.DelChars = DelChars
  exports.SpliceChars = SpliceChars
  exports.InsertRowSibling = InsertRowSibling
  exports.DeleteRow = DeleteRow
  exports.AttachRow = AttachRow
  exports.DetachRow = DetachRow
)(if typeof exports isnt 'undefined' then exports else window.actions = {})

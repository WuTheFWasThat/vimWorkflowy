###
Takes in keys, and, based on the keybindings (see keyBindings.coffee), manipulates the view (see view.coffee)

The KeyHandler class manages the state of what keys have been input, dealing with the logic for
- handling multi-key sequences, i.e. a key that semantically needs another key (e.g. the GO command, `g` in vim)
- handling motions and commands that take motions
- combining together and saving sequences of commands (important for the REPEAT command, `.` in vim, for macros, and for number prefixes, e.g. 3j)
- dropping sequences of commands that are invalid
- telling the view when to save (i.e. the proper checkpoints for undo and redo)
It maintains custom logic for this, for each mode.
(NOTE: hopefully this logic can be more unified!  It is currently quite fragile)

the KeyStream class is a helper class which deals with queuing and checkpointing a stream of key events
###

# imports
if module?
  global.EventEmitter = require('./eventEmitter.coffee')
  global.errors = require('./errors.coffee')
  global.Menu = require('./menu.coffee')
  global.constants = require('./constants.coffee')
  global.Logger = require('./logger.coffee')

(() ->
  MODES = constants.MODES

  # manages a stream of keys, with the ability to
  # - queue keys
  # - wait for more keys
  # - flush sequences of keys
  # - save sequences of relevant keys
  class KeyStream extends EventEmitter
    constructor: (keys = []) ->
      super

      @queue = [] # queue so that we can read group of keys, like 123 or fy
      @lastSequence = [] # last key sequence
      @index = 0
      @checkpoint_index = 0
      @waiting = false

      for key in keys
        @enqueue key

    empty: () ->
      return @queue.length == 0

    done: () ->
      return @index == @queue.length

    rewind: () ->
      @index = @checkpoint_index

    enqueue: (key) ->
      @queue.push key
      @waiting = false

    dequeue: () ->
      if @index == @queue.length then return null
      return @queue[@index++]

    checkpoint: () ->
      @checkpoint_index = @index

    # means we are waiting for another key before we can do things
    wait: () ->
      @waiting = true
      do @rewind

    save: () ->
      processed = do @forget
      @lastSequence = processed
      @emit 'save'

    forget: () ->
      dropped = @queue.splice 0, @index
      @index = 0
      return dropped

  class KeyHandler

    constructor: (view, keyBindings) ->
      @view = view

      @keyBindings = keyBindings

      @macros = {}
      @recording = null
      @recording_key = null

      @keyStream = new KeyStream
      @keyStream.on 'save', () =>
        do @view.save

    handleKey: (key) ->
      if do @view.showingSettings
          @view.handleSettings key
          return true
      Logger.logger.debug 'Handling key:', key
      @keyStream.enqueue key
      if @recording
        @recording.enqueue key
      handled = @processKeys @keyStream
      return handled

    # NOTE: handled tells the eventEmitter whether to preventDefault or not
    processKeys: (keyStream) ->
      handled = false
      while not keyStream.done() and not keyStream.waiting
        do keyStream.checkpoint
        handled = (@processOnce keyStream) or handled
      # TODO: stop re-rendering everything every time?
      do @view.render
      return handled

    processOnce: (keyStream) ->
      if @view.mode == MODES.NORMAL
        return @processNormalMode keyStream
      else if @view.mode == MODES.INSERT
        return @processInsertMode keyStream
      else if @view.mode == MODES.VISUAL
        return @processVisualMode keyStream
      else if @view.mode == MODES.VISUAL_LINE
        return @processVisualLineMode keyStream
      else if @view.mode == MODES.SEARCH
        return @processSearchMode keyStream
      else if @view.mode == MODES.MARK
        return @processMarkMode keyStream
      else
        throw new errors.UnexpectedValue "mode", @view.mode

    processInsertMode: (keyStream) ->
      key = do keyStream.dequeue
      if key == null then throw errors.GenericError 'Got no key in insert mode'
      # if key == null then return do keyStream.wait

      bindings = @keyBindings.bindings[MODES.INSERT]

      if not (key of bindings)
        if key == 'shift+enter'
          key = '\n'
        else if key == 'space' or key == 'shift+space'
          key = ' '
        if key.length > 1
          return false
        obj = {char: key}
        for property in constants.text_properties
          if @view.cursor.getProperty property then obj[property] = true
        @view.addCharsAtCursor [obj], {cursor: {pastEnd: true}}
        return true

      info = bindings[key]

      if info.motion
        motion = info.fn
        motion @view.cursor, {pastEnd: true}
      else
        fn = info.insert
        context = {
          view: @view,
          keyStream: keyStream,
        }
        fn.apply context, []

      return true

    processVisualMode: (keyStream) ->
      key = do keyStream.dequeue
      if key == null then throw errors.GenericError 'Got no key in visual mode'
      # if key == null then return do keyStream.wait

      bindings = @keyBindings.bindings[MODES.VISUAL]

      if not (key of bindings)
        # getMotion using normal mode motions
        # TODO: make this relationship more explicit via a separate motions dictionary
        [motion, repeat] = @getMotion keyStream, key
        if motion == null
          if keyStream.waiting # motion continuing
            return true
          else
            do keyStream.forget
            return false

        # this is necessary until we figure out multiline
        tmp = do @view.cursor.clone

        for i in [1..repeat]
          motion tmp, {pastEnd: true}

        if tmp.row != @view.cursor.row # only allow same-row movement
          @view.showMessage "Visual mode currently only works on one line", {text_class: 'error'}
          return true
        @view.cursor.from tmp
        return true

      info = bindings[key]

      context = {
        view: @view,
        keyStream: @keyStream,
      }
      info.visual.apply context, []
      return true

    processVisualLineMode: (keyStream) ->
      key = do keyStream.dequeue
      if key == null then throw errors.GenericError 'Got no key in visual line mode'
      # if key == null then return do keyStream.wait

      bindings = @keyBindings.bindings[MODES.VISUAL_LINE]

      if not (key of bindings)
        # getMotion using normal mode motions
        # TODO: make this relationship more explicit via a separate motions dictionary
        [motion, repeat] = @getMotion keyStream, key
        if motion == null
          if keyStream.waiting # motion continuing
            return true
          else
            do keyStream.forget
            return false

        for i in [1..repeat]
          motion @view.cursor, {pastEnd: true}
        return true

      info = bindings[key]

      [parent, index1, index2] = do @view.getVisualLineSelections
      # TODO: get a row, instead of id, for parent
      context = {
        view: @view,
        keyStream: @keyStream,
        row_start_i: index1
        row_end_i: index2
        row_start: (@view.data.getChildren parent)[index1]
        row_end: (@view.data.getChildren parent)[index2]
        parent: parent
        num_rows: index2 - index1 + 1
      }
      info.visual_line.apply context, []
      return true

    processSearchMode: (keyStream) ->
      key = do keyStream.dequeue
      if key == null then throw errors.GenericError 'Got no key in search mode'

      bindings = @keyBindings.bindings[MODES.SEARCH]

      menu_view = @view.menu.view

      if not (key of bindings)
        if key == 'shift+enter'
          key = '\n'
        else if key == 'space'
          key = ' '
        if key.length > 1
          return false
        menu_view.addCharsAtCursor [{char: key}], {cursor: {pastEnd: true}}
      else
        info = bindings[key]

        if info.motion
          motion = info.fn
          motion menu_view.cursor, {pastEnd: true}
        else
          fn = info.search
          args = []
          context = {
            view: @view,
            keyStream: @keyStream
          }
          fn.apply context, args

      if @view.mode != MODES.NORMAL
        do @view.menu.update

      do keyStream.forget
      return true

    processMarkMode: (keyStream) ->
      key = do keyStream.dequeue
      if key == null then throw errors.GenericError 'Got no key in mark mode'

      bindings = @keyBindings.bindings[MODES.MARK]

      mark_view = @view.markview

      if not (key of bindings)
        # must be non-whitespace
        if key.length > 1
          return false
        if /^\S*$/.test(key)
          mark_view.addCharsAtCursor [{char: key}], {cursor: {pastEnd: true}}
      else
        info = bindings[key]

        if info.motion
          motion = info.fn
          motion mark_view.cursor, {pastEnd: true}
        else
          fn = info.mark
          args = []
          context = {
            view: @view
            keyStream: @keyStream
          }
          fn.apply context, args
      return true

    # takes keyStream, key, returns repeat number and key
    getRepeat: (keyStream, key = null) ->
      if key == null
        key = do keyStream.dequeue
      begins = [1..9].map ((x) -> return do x.toString)
      continues = [0..9].map ((x) -> return do x.toString)
      if key not in begins
        return [1, key]
      numStr = key
      key = do keyStream.dequeue
      if key == null then return [null, null]
      while key in continues
        numStr += key
        key = do keyStream.dequeue
        if key == null then return [null, null]
      return [parseInt(numStr), key]

    # useful when you expect a motion
    getMotion: (keyStream, motionKey, bindings = @keyBindings.bindings[MODES.NORMAL], repeat = 1) =>
      [motionRepeat, motionKey] = @getRepeat keyStream, motionKey
      repeat = repeat * motionRepeat

      if motionKey == null
        do keyStream.wait
        return [null, repeat]

      info = bindings[motionKey] || {}
      if not info.motion
        do keyStream.forget
        return [null, repeat]

      fn = null

      if info.continue
        key = do keyStream.dequeue
        if key == null
          do keyStream.wait
          if info.fn # bit of a hack, for easy-motion
            info.fn.apply {view: @view}
          return [null, repeat]
        fn = info.continue.bind @, key
      else if info.bindings
        answer = (@getMotion keyStream, null, info.bindings, repeat)
        return answer
      else if info.fn
        fn = info.fn

      return [fn, repeat]

    processNormalMode: (keyStream, bindings = @keyBindings.bindings[MODES.NORMAL], repeat = 1) ->
      [newrepeat, key] = @getRepeat keyStream
      if key == null
        do keyStream.wait
        return true
      # TODO: something better for passing repeat through?
      repeat = repeat * newrepeat

      fn = null
      args = []

      if not (key of bindings)
        if 'MOTION' of bindings
          info = bindings['MOTION']

          # note: this uses original bindings to determine what's a motion
          [motion, repeat] = @getMotion keyStream, key, @keyBindings.bindings[MODES.NORMAL], repeat
          if motion == null
            do keyStream.forget
            return false

          cursor = do @view.cursor.clone
          for i in [1..repeat]
            motion cursor, {pastEnd: true, pastEndWord: true}

          args.push cursor
        else
          do keyStream.forget
          return false
      else
        info = bindings[key] || {}

      if info.bindings
        return @processNormalMode keyStream, info.bindings, repeat

      if info.motion
        # note: this uses *new* bindings to determine what's a motion
        [motion, repeat] = @getMotion keyStream, key, bindings, repeat
        if motion == null
          return true

        for j in [1..repeat]
          motion @view.cursor, ''
        do keyStream.forget
        return true

      if info.menu
        @view.setMode MODES.SEARCH
        @view.menu = new Menu @view.menuDiv, (info.menu.bind @, @view)
        do @view.menu.update
        do keyStream.forget
        return true

      if info.continue
        key = do keyStream.dequeue
        if key == null then return do keyStream.wait

        fn = info.continue
        args.push key
      else if info.fn
        fn = info.fn

      if fn
        context = {
          view: @view,
          repeat: repeat,
        }
        fn.apply context, args

      if info.to_mode
        @view.setMode info.to_mode
        if info.to_mode == MODES.SEARCH
          do keyStream.forget
        return true

      if info.name == 'RECORD_MACRO'
        if @recording == null
          nkey = do keyStream.dequeue
          if nkey == null then return do keyStream.wait
          @recording = new KeyStream
          @recording_key = nkey
        else
          macro = @recording.queue
          do macro.pop # pop off the RECORD_MACRO itself
          @macros[@recording_key] = macro
          @recording = null
          @recording_key = null
        do keyStream.forget
        return true
      if info.name == 'PLAY_MACRO'
          nkey = do keyStream.dequeue
          if nkey == null then return do keyStream.wait
          recording = @macros[nkey]
          if recording == undefined then return do keyStream.forget

          for i in [1..repeat]
            # the recording shouldn't save, (i.e. no @view.save)
            recordKeyStream = new KeyStream recording
            @processKeys recordKeyStream
          # but we should save the macro-playing sequence itself
          do keyStream.save
          return true

      if info.name == 'REPLAY'
        for i in [1..repeat]
          newStream = new KeyStream @keyStream.lastSequence
          newStream.on 'save', () =>
            do @view.save
          @processKeys newStream
        do keyStream.forget
        return true

      if info.drop
        do keyStream.forget
      else
        do keyStream.save
      return true

  module?.exports = KeyHandler
  window?.KeyHandler = KeyHandler
)()

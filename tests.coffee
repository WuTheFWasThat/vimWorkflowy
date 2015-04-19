require 'coffee-script/register'
assert = require 'assert'

Data = require './assets/js/data.coffee'
View = require './assets/js/view.coffee'
KeyBindings = require './assets/js/keyBindings.coffee'

class TestCase
  constructor: (serialized = ['']) ->
    @data = new Data
    @data.load serialized

    @view = new View null, @data
    @view.render = -> return
    @view.renderHelper = -> return
    @view.drawRow = -> return
    @keybinder = new KeyBindings null, null, @view

  sendKeys: (keys) ->
    for key in keys
      @sendKey key

  sendKey: (key) ->
    @keybinder.handleKey key

  expect: (expected) ->
    serialized = do @data.serialize
    assert.deepEqual serialized.children, expected

t = new TestCase
t.sendKey 'i'
t.sendKeys 'hello world'
t.sendKey 'esc'
t.expect ['hello world']

t.sendKeys 'xxxsu'
t.expect ['hello wu']

t.sendKey 'esc'
t.sendKeys 'uuuuu'
t.expect ['hello world']

t.sendKey 'esc'
for i in [1..5]
  t.sendKey 'ctrl+r'
t.expect ['hello wu']

t.sendKeys '0x'
t.expect ['ello wu']

t.sendKeys '$x'
t.expect ['ello w']

# delete on the last character should send the cursor back one
t.sendKeys 'hx'
t.expect ['ellow']

t.sendKeys 'Iy'
t.sendKey 'esc'
t.expect ['yellow']

t.sendKeys 'Ay'
t.sendKey 'esc'
t.expect ['yellowy']

t.sendKeys 'a purple'
t.sendKey 'esc'
t.expect ['yellowy purple']

t = new TestCase ['hello']

t.sendKey '$'
# i + esc moves the cursor back a character
for i in [1..3]
  t.sendKey 'i'
  t.sendKey 'esc'
t.sendKeys 'ra'
t.expect ['hallo']

# a + esc doesn't
for i in [1..3]
  t.sendKey 'a'
  t.sendKey 'esc'
t.sendKeys 'ru'
t.expect ['hullo']

t = new TestCase ['hello world']

# make sure delete and then undo doesn't move the cursor
t.sendKeys '$hhxux'
t.expect ['hello wold']

# delete on last character should work
t.sendKeys '$dl'
t.expect ['hello wol']
# and it should send the cursor back one
t.sendKey 'x'
t.expect ['hello wo']
# replace
t.sendKeys 'ru'
t.expect ['hello wu']
# undo and redo it
t.sendKeys 'u'
t.expect ['hello wo']
t.sendKey 'ctrl+r'
t.expect ['hello wu']
# hitting left should send the cursor back one more
t.sendKey 'left'
t.sendKeys 'x'
t.expect ['hello u']

t.sendKey '0'
t.sendKey 'right'
t.sendKey 'x'
t.expect ['hllo u']

t.sendKeys '$c0ab'
t.sendKey 'esc'
t.expect ['abu']

# does nothing
t.sendKeys 'dycy'
t.expect ['abu']

# test the shit out of b
t = new TestCase ['the quick brown fox   jumped   over the lazy dog']
t.sendKeys '$bx'
t.expect ['the quick brown fox   jumped   over the lazy og']
t.sendKeys 'bx'
t.expect ['the quick brown fox   jumped   over the azy og']
t.sendKeys 'hbx'
t.expect ['the quick brown fox   jumped   over he azy og']
t.sendKeys 'hhbx'
t.expect ['the quick brown fox   jumped   ver he azy og']
t.sendKeys 'bx'
t.expect ['the quick brown fox   umped   ver he azy og']
t.sendKeys 'bdb'
t.expect ['the quick fox   umped   ver he azy og']
t.sendKeys 'u'
t.expect ['the quick brown fox   umped   ver he azy og']
t.sendKey 'ctrl+r'
t.expect ['the quick fox   umped   ver he azy og']
t.sendKeys 'hhhdb'
t.expect ['the ck fox   umped   ver he azy og']
t.sendKeys 'bx'
t.expect ['he ck fox   umped   ver he azy og']
t.sendKeys 'bbbbx'
t.expect ['e ck fox   umped   ver he azy og']
t = new TestCase ['the']
t.sendKeys '0db'
t.expect ['the']

# test the shit out of e
t = new TestCase ['the quick brown fox   jumped   over the lazy dog']
t.sendKeys 'ex'
t.expect ['th quick brown fox   jumped   over the lazy dog']
t.sendKeys 'ex'
t.expect ['th quic brown fox   jumped   over the lazy dog']
t.sendKeys 'lex'
t.expect ['th quic brow fox   jumped   over the lazy dog']
t.sendKeys 'llex'
t.expect ['th quic brow fo   jumped   over the lazy dog']
t.sendKeys 'ex'
t.expect ['th quic brow fo   jumpe   over the lazy dog']
t.sendKeys 'ede'
t.expect ['th quic brow fo   jumpe   ove lazy dog']
t.sendKeys 'u'
t.expect ['th quic brow fo   jumpe   over the lazy dog']
t.sendKey 'ctrl+r'
t.expect ['th quic brow fo   jumpe   ove lazy dog']
t.sendKeys 'lllde'
t.expect ['th quic brow fo   jumpe   ove la dog']
t.sendKeys 'ex'
t.expect ['th quic brow fo   jumpe   ove la do']
t.sendKeys 'eeeex'
t.expect ['th quic brow fo   jumpe   ove la d']
t = new TestCase ['the']
t.sendKeys '$de'
t.expect ['th']

# test the shit out of w
t = new TestCase ['the quick brown fox   jumped   over the lazy dog']
t.sendKeys 'wx'
t.expect ['the uick brown fox   jumped   over the lazy dog']
t.sendKeys 'lwx'
t.expect ['the uick rown fox   jumped   over the lazy dog']
t.sendKeys 'elwx'
t.expect ['the uick rown ox   jumped   over the lazy dog']
t.sendKeys 'wx'
t.expect ['the uick rown ox   umped   over the lazy dog']
t.sendKeys 'wdw'
t.expect ['the uick rown ox   umped   the lazy dog']
t.sendKeys 'u'
t.expect ['the uick rown ox   umped   over the lazy dog']
t.sendKey 'ctrl+r'
t.expect ['the uick rown ox   umped   the lazy dog']
t.sendKeys 'lldw'
t.expect ['the uick rown ox   umped   thlazy dog']
t.sendKeys 'wx'
t.expect ['the uick rown ox   umped   thlazy og']
t.sendKeys 'wx'
t.expect ['the uick rown ox   umped   thlazy o']
t.sendKeys 'wwwwx'
t.expect ['the uick rown ox   umped   thlazy ']
t = new TestCase ['the']
t.sendKeys '$dw'
t.expect ['th']

# make sure cursor doesn't go before line
t = new TestCase ['blahblah']
t.sendKeys '0d$iab'
t.expect ['ab']

# test the shit out of repeat
t = new TestCase ['']
t.sendKeys '....'
t.expect ['']
t.sendKeys 'irainbow'
t.sendKey 'esc'
t.sendKey '.'
t.expect ['rainborainboww']
t.sendKeys 'x...'
t.expect ['rainborain']

t = new TestCase ['the quick brown fox   jumped   over the lazy dog']
t.sendKeys 'dw'
t.expect ['quick brown fox   jumped   over the lazy dog']
t.sendKeys '..'
t.expect ['fox   jumped   over the lazy dog']
t.sendKeys 'u.'
t.expect ['fox   jumped   over the lazy dog']
t.sendKeys 'dy' # nonsense
t.expect ['fox   jumped   over the lazy dog']
t.sendKeys '..'
t.expect ['over the lazy dog']
t.sendKeys 'rxll.w.e.$.'
t.expect ['xvxr xhx lazy dox']
t.sendKeys 'cbxero'
t.sendKey 'esc'
t.expect ['xvxr xhx lazy xerox']
t.sendKeys 'b.'
t.expect ['xvxr xhx xeroxerox']
t.sendKeys '.'
t.expect ['xvxr xhx xerooxerox']

# repeat works on replace
t = new TestCase ['blahblah']
t.sendKeys 'rgllll.'
t.expect ['glahglah']

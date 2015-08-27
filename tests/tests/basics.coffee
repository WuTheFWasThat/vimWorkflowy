require 'coffee-script/register'
TestCase = require '../testcase.coffee'

new TestCase [''], {}, (t) ->
  t.sendKey 'i'
  t.sendKeys 'hello world'
  t.sendKey 'esc'
  t.expect ['hello world']

  t.sendKeys 'xxxsu'
  t.expect ['hello wu']

  t.sendKey 'esc'
  t.sendKeys 'uuuu'
  t.expect ['hello world']
  t.sendKeys 'u'
  t.expect ['']

  t.sendKey 'ctrl+r'
  t.expect ['hello world']
  for i in [1..4]
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

# test that redo doesn't go past latest
new TestCase ['thing'], { name: "test that redo doesn't go past latest" }, (t) ->
  t.sendKey 'x'
  t.expect ['hing']
  t.sendKeys 'u'
  t.expect ['thing']
  t.sendKey 'ctrl+r'
  t.sendKey 'ctrl+r'
  t.sendKey 'ctrl+r'
  t.expect ['hing']
  t.sendKeys 'u'
  t.expect ['thing']

new TestCase ['hello'], { name: "i+esc moves the cursor back a character, a + esc doesn't" }, (t) ->
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

new TestCase ['hello world'], {}, (t) ->

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

# make sure cursor doesn't go before line
new TestCase ['blahblah'], {}, (t) ->
  t.sendKeys '0d$iab'
  t.expect ['ab']

#########
# REPEAT
#########

new TestCase [''], {}, (t) ->
  t.sendKeys '....'
  t.expect ['']
  t.sendKeys 'irainbow'
  t.sendKey 'esc'
  t.sendKey '.'
  t.expect ['rainborainboww']
  t.sendKeys 'x...'
  t.expect ['rainborain']

new TestCase ['the quick brown fox   jumped   over the lazy dog'], {}, (t) ->
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

new TestCase ['vim is great'], { name: "repeat works on c" }, (t) ->
  t.sendKeys 'ceblah'
  t.sendKey 'esc'
  t.sendKeys 'w.w.'
  t.expect ['blah blah blah']

new TestCase ['obladi oblada'], { name: "repeat works on replace" }, (t) ->
  t.sendKeys 'eroehl.'
  t.expect ['oblado oblado']

#########
# NUMBERS
#########

new TestCase ['obladi oblada o lee lee o lah lah'], { name: "numbers works on movement" }, (t) ->
  t.sendKeys '5lx'
  t.expect ['oblad oblada o lee lee o lah lah']
  t.sendKeys '6wx'
  t.expect ['oblad oblada o lee lee o ah lah']
  t.sendKeys '7$x'
  t.expect ['oblad oblada o lee lee o ah la']
  t.sendKeys '5bx'
  t.expect ['oblad oblada o ee lee o ah la']
  # numbers repeat works on c
  t.sendKeys '$5cb'
  t.sendKeys 'blah blah blah'
  t.sendKey 'esc'
  t.expect ['oblad oblada o blah blah blaha']
  # numbers repeat works on d
  t.sendKeys '03de'
  t.expect [' blah blah blaha']
  t.sendKeys 'u'
  t.expect ['oblad oblada o blah blah blaha']
  # number works within movement
  t.sendKeys 'd3e'
  t.expect [' blah blah blaha']
  # and undo does it all at once
  t.sendKeys 'u'
  t.expect ['oblad oblada o blah blah blaha']
  # try cut too
  t.sendKeys 'c3eblah'
  t.sendKey 'esc'
  t.expect ['blah blah blah blaha']

new TestCase ['1234123412341234 is my credit card'], { name: "numbers repeat works on replace" }, (t) ->
  t.sendKeys '12r*'
  t.expect ['************1234 is my credit card']
  t.sendKeys 'l12X'
  t.expect ['1234 is my credit card']
  # number repeat works with undo
  t.sendKeys 'u'
  t.expect ['************1234 is my credit card']
  t.sendKeys 'u'
  t.expect ['1234123412341234 is my credit card']
  t.sendKey 'ctrl+r'
  t.expect ['************1234 is my credit card']
  t.sendKeys 'lX.................................'
  t.expect ['1234 is my credit card']
  # number repeat works on undo
  t.sendKeys '8u'
  t.expect ['********1234 is my credit card']
  t.sendKeys '6u'
  t.expect ['1234123412341234 is my credit card']

new TestCase ['empty', ''], { name: "test x on empty row" }, (t) ->
  t.sendKeys 'ru'
  t.expect ['umpty', '']
  t.sendKeys 'jxk.'
  t.expect ['mpty', '']

new TestCase ['empty', ''], { name: "test join where second row is empty" }, (t) ->
  t.sendKeys 'J'
  t.expect ['empty']

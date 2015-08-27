require 'coffee-script/register'
TestCase = require '../testcase.coffee'

new TestCase ['some random text'], (t) ->
  t.sendKeys 'wD'
  t.expect ['some ']
  t.sendKeys 'D'
  t.expect ['some']
  t.sendKeys 'u'
  t.expect ['some ']
  t.sendKeys 'u'
  t.expect ['some random text']

new TestCase ['some random text'], (t) ->
  t.sendKeys '$D'
  t.expect ['some random tex']
  # paste should work
  t.sendKeys 'P'
  t.expect ['some random tetx']

# in insert mode
new TestCase ['some random text'], (t) ->
  t.sendKeys 'wi'
  t.sendKey 'ctrl+k'
  t.expect ['some ']
  t.sendKey 'ctrl+u'
  t.expect ['']
  t.sendKey 'ctrl+y'
  t.expect ['some ']
  t.sendKey 'esc'
  t.sendKeys 'u'
  t.expect ['some random text']

# in insert mode
new TestCase ['some random text'], (t) ->
  t.sendKeys 'wi'
  t.sendKey 'ctrl+u'
  t.expect ['random text']
  t.sendKey 'ctrl+k'
  t.expect ['']
  t.sendKey 'ctrl+y'
  t.expect ['random text']
  t.sendKey 'esc'
  t.sendKeys 'u'
  t.expect ['some random text']

# in insert mode, ctrl+y brings you past end?
new TestCase ['some random text'], (t) ->
  t.sendKeys 'wi'
  t.sendKey 'ctrl+k'
  t.expect ['some ']
  t.sendKey 'ctrl+y'
  t.expect ['some random text']
  t.sendKey 's'
  t.expect ['some random texts']

# not undoable when nothing
new TestCase ['some random text'], (t) ->
  t.sendKeys 'x'
  t.expect ['ome random text']
  t.sendKeys '$a'
  t.sendKey 'ctrl+k'
  t.sendKey 'esc'
  t.expect ['ome random text']
  t.sendKeys 'u'
  t.expect ['some random text']

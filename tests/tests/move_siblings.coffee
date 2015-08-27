require 'coffee-script/register'
TestCase = require '../testcase.coffee'

new TestCase [
  { text: 'one', children: [
    'uno',
  ] }
  { text: 'two', children: [
    'dos',
  ] }
  { text: 'tacos', children: [
    'tacos',
  ] }
], { name: "test alt+j and alt+k" }, (t) ->
  t.sendKeys 'x'
  t.sendKey 'alt+j'
  t.sendKeys 'x'
  t.expect [
    { text: 'ne', children: [
      'uno',
    ] }
    { text: 'wo', children: [
      'dos',
    ] }
    { text: 'tacos', children: [
      'tacos',
    ] }
  ]
  t.sendKey 'alt+j'
  t.sendKeys 'x'
  t.sendKey 'alt+j'
  t.sendKeys 'x'
  t.expect [
    { text: 'ne', children: [
      'uno',
    ] }
    { text: 'wo', children: [
      'dos',
    ] }
    { text: 'cos', children: [
      'tacos',
    ] }
  ]
  t.sendKey 'alt+k'
  t.sendKeys 'x'
  t.expect [
    { text: 'ne', children: [
      'uno',
    ] }
    { text: 'o', children: [
      'dos',
    ] }
    { text: 'cos', children: [
      'tacos',
    ] }
  ]
  t.sendKey 'alt+k'
  t.sendKeys 'x'
  t.expect [
    { text: 'e', children: [
      'uno',
    ] }
    { text: 'o', children: [
      'dos',
    ] }
    { text: 'cos', children: [
      'tacos',
    ] }
  ]
  t.sendKey 'alt+k'
  t.sendKeys 'x'
  t.expect [
    { text: '', children: [
      'uno',
    ] }
    { text: 'o', children: [
      'dos',
    ] }
    { text: 'cos', children: [
      'tacos',
    ] }
  ]

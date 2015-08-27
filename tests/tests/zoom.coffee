require 'coffee-script/register'
TestCase = require '../testcase.coffee'

new TestCase [
  { text: 'first', children: [
    'second'
  ] },
  'third'
], { name: "test changing view root" }, (t) ->
  t.sendKey ']'
  t.expect [
    { text: 'first', children: [
      'second'
    ] },
    'third'
  ]
  t.sendKeys 'jjx'
  t.expect [
    { text: 'first', children: [
      'econd'
    ] },
    'third'
  ]
  # zoom out stays on same line
  t.sendKey '['
  t.sendKeys 'x'
  t.expect [
    { text: 'first', children: [
      'cond'
    ] },
    'third'
  ]
  t.sendKeys 'jx'
  t.expect [
    { text: 'first', children: [
      'cond'
    ] },
    'hird'
  ]

new TestCase [
  { text: 'first', children: [
    { text: 'second', children: [
      'third'
    ] },
  ] },
], { name: "zoom in on collapsed works but doesn't uncollapse" }, (t) ->
  t.sendKeys 'zjx'
  t.expect [
    { text: 'irst', collapsed: true, children: [
      { text: 'second', children: [
        'third'
      ] },
    ] },
  ]
  t.sendKeys ']x'
  t.expect [
    { text: 'irst', collapsed: true, children: [
      { text: 'econd', children: [
        'third'
      ] },
    ] },
  ]
  # but now zoom out moves the cursor, since otherwise it's hidden
  t.sendKeys '[x'
  t.expect [
    { text: 'rst', collapsed: true, children: [
      { text: 'econd', children: [
        'third'
      ] },
    ] },
  ]

new TestCase [
  { text: 'first', children: [
    { text: 'second', children: [
      { text: 'third', children: [
        'fourth'
      ] },
    ] },
  ] },
], { name: "test full zoom" }, (t) ->
  t.sendKeys 'jjj}x'
  t.expect [
    { text: 'first', children: [
      { text: 'second', children: [
        { text: 'third', children: [
          'ourth'
        ] },
      ] },
    ] },
  ]

new TestCase [
  { text: 'first', children: [
    { text: 'second', children: [
      { text: 'third', children: [
        'fourth'
      ] },
    ] },
  ] },
], {}, (t) ->
  t.sendKeys '$x$' # second dollar needed, since x ruins it
  t.expect [
    { text: 'firs', children: [
      { text: 'second', children: [
        { text: 'third', children: [
          'fourth'
        ] },
      ] },
    ] },
  ]
  t.sendKeys 'jj}x' # keeps the fact that column is last line!
  t.expect [
    { text: 'firs', children: [
      { text: 'second', children: [
        { text: 'third', children: [
          'fourt'
        ] },
      ] },
    ] },
  ]
  t.sendKeys '{x' # keeps cursor on fourth row
  t.expect [
    { text: 'firs', children: [
      { text: 'second', children: [
        { text: 'third', children: [
          'four'
        ] },
      ] },
    ] },
  ]
  t.sendKeys 'gg$x' # but we can go back up now
  t.expect [
    { text: 'fir', children: [
      { text: 'second', children: [
        { text: 'third', children: [
          'four'
        ] },
      ] },
    ] },
  ]

new TestCase [
  { text: 'first', children: [
    { text: 'second', children: [
      'third'
    ] },
  ] },
], { name: "can't unindent too far out when zoomed in" }, (t) ->
  t.sendKeys 'jj'
  t.sendKey 'shift+tab'
  t.expect [
    { text: 'first', children: [
      'second'
      'third'
    ] },
  ]
  t.sendKey 'u'
  t.expect [
    { text: 'first', children: [
      { text: 'second', children: [
        'third'
      ] },
    ] },
  ]
  t.sendKey '}'
  t.sendKey 'shift+tab'
  t.expect [
    { text: 'first', children: [
      { text: 'second', children: [
        'third'
      ] },
    ] },
  ]


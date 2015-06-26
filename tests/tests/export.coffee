TestCase = require '../testcase.coffee'

# Test export formats
t = new TestCase [
  { line: 'first', children: [
    'second'
  ] },
  'third'
]
t.expectExport 'text/plain', "- \n  - first\n    - second\n  - third"
t.expectExport 'application/json', "{\n  \"line\": \"\",\n  \"children\": [\n    {\n      \"line\": \"first\",\n      \"children\": [\n        \"second\"\n      ]\n    },\n    \"third\"\n  ]\n}"


# Make sure zoom does not affect export
t = new TestCase [
  { line: 'first', children: [
    'second'
  ] },
  'third'
]
t.sendKey 'down'
t.sendKey 'alt+l'
t.expectExport 'text/plain', "- \n  - first\n    - second\n  - third"

# vimflowy

This is a productivity tool which draws great inspiration from workflowy and vim

Try it out [here](https://vimflowy.bitballoon.com)!

## TODO ##

fixes
- warn another tab if something has been modified??
- scale better:
  - limit search results
- break up tests into multiple files...
- style stuff better
- rethink default fold hotkeys (z+coaCOA)?

Features
- make hotkeys customizable
- visual mode
- visual line mode
- macros
- there should be a way to yank just 1 line without children?
- yc -> clone?
- gp = go parent?
- implement some form of marks (m[a-z] or m[string]?  'a or '[string])
  - tagging, e.g. @mark that links to it
- implement `ctrl+o`, `g,`, `g;`
- find/replace?
- line numbers?

Other
- make a video

## KNOWN ISSUES: ##

- e/b/w don't cross onto next line

Known (intentional) inconsistencies with vi:
- undoing operations always puts your cursor where it was.  (This is not true in vim: try going to the middle of a line and typing d0u)
- in vim, cw works like ciw, which is inconsistent/counterintuitive
- 5$ doesn't work
- 100rx will replace as many as it can
- t and T work when you use them repeatedly
- I goes to the beginning of the line, irrespective of whitespace
- yank (y) never moves the cursor (in vim, yb and yh move the cursor to the start of the yank region)

## CONTRIBUTE: ##

Please send pull requests!
You may contact me at [githubusername]@gmail.com as well

## LICENSE ##

MIT: http://wuthefwasthat.mit-license.org/

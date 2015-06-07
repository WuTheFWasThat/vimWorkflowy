# vimflowy

This is a productivity tool which draws great inspiration from workflowy and vim

Try it out [here](https://vimflowy.bitballoon.com)!

# NOTES #

- The app is entirely local - the storage is localStorage, so it should be used in only one browser
- Currently, weird things happen when you use it in multiple tabs

## TODO ##

UI
  - generally style stuff better
  - customizable stylesheets?  e.g. one vim-flavored and one workflowy-flavored, light and dark background
  - click location to move cursor
  - mouse drag to make cursor select area?
  - mouse drag bullets around?
  - warn another tab if something has been modified??

Fixes
  - scale better:
    - limit search results
  - rethink default fold hotkeys (z+coaCOA)?

Internal stuff
  - break up tests into multiple files...
  - add logging?
  - rethink data/view separation

Features
  - data import and export mechanism
  - make hotkeys customizable
  - visual mode
  - visual line mode
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

Known (intentional) inconsistencies with vi (WONTFIX without further discussion):
- undoing operations always puts your cursor where it was.  (This is not true in vim: try going to the middle of a line and typing d0u)
- in vim, cw works like ciw, which is inconsistent/counterintuitive
- 5$ doesn't work
- 100rx will replace as many as it can
- t and T work when you use them repeatedly
- I goes to the beginning of the line, irrespective of whitespace
- yank (y) never moves the cursor (in vim, yb and yh move the cursor to the start of the yank region)
- macros
  - redo operator (.) redoes entire macros rather than the last sequence (easy to fix, but not desired IMO)
  - not implemented using registers (weird quirk of vim IMO)

## CONTRIBUTE: ##

Please send pull requests!
You may contact me at [githubusername]@gmail.com as well

## LICENSE ##

MIT: http://wuthefwasthat.mit-license.org/

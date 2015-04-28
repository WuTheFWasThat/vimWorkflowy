# vimflowy?? #

## TODO ##

implement y and p for dd/cc
implement J
implement folding
implement ctrl+o

## KNOWN ISSUES: ##

- j/k don't preserve the column
- e/b/w don't cross onto next line

Firstly, there are many known inconsistencies with vi.  Many are intentional.  Here is a list of known differences:
- undoing operations always puts your cursor where it was.  (This is not true in vim: try going to the middle of a line and typing d0u)
- 2dw causes only the last dw to be in register.  d2w causes both to be in register (in vim, both would yank both)
- in vim, cw works like ciw, which is inconsistent/counterintuitive
- 5$ doesn't work
- 100rx will replace as many as it can
- t and T work when you use them repeatedly
- I goes to the beginning of the line, irrespective of whitespace
- yank (y) never moves the cursor (in vim, yb and yh move the cursor to the start of the yank region)

## CONTRIBUTE: ##


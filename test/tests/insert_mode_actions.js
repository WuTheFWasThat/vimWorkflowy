/* globals describe, it */
import TestCase from '../testcase';

// TODO: this file needs more tests!
// tests ctrl+e, ctrl+w, ctrl+u, ctrl+k, ctrl+y

describe('delete to end', () =>
  it('keeps the cursor past the end', function() {
    let t = new TestCase(['happy ending']);
    t.sendKeys('i');
    t.sendKey('alt+f');
    t.sendKey('ctrl+k');
    t.sendKeys('feet');
    t.sendKey('esc');
    return t.expect(['happy feet']);
  })

);

describe('insert mode actions', () =>
  it('works in tricky case redoing actions in normal mode', function() {
    let t = new TestCase(['bug reproduce']);
    t.sendKeys('i');
    t.sendKey('ctrl+e'); // put cursor at end, this will be remembered by the cursor
    t.sendKey('ctrl+w');
    t.expect(['bug ']);
    t.sendKey('ctrl+w');
    t.expect(['']);
    t.sendKey('ctrl+y');
    t.expect(['bug ']);
    t.sendKey('ctrl+y');
    t.expect(['bug bug ']);
    t.sendKey('esc');
    t.sendKey('u');
    t.expect(['bug reproduce']);
    // even though we remembered cursor to be past e, it gets moved back,
    // since we're now in normal mode
    t.sendKey('x');
    return t.expect(['bug reproduc']);
  })

);


/* globals describe, it */
import TestCase from '../testcase';

describe('random set of basic tests', function() {
  it('tests adding, deleting, undoing, and redoing', function() {
    let t = new TestCase(['']);
    t.sendKey('i');
    t.sendKeys('hello world');
    t.sendKey('esc');
    t.expect(['hello world']);

    t.sendKeys('xxxsu');
    t.expect(['hello wu']);

    t.sendKey('esc');
    t.sendKeys('uuuu');
    t.expect(['hello world']);
    t.sendKeys('u');
    t.expect(['']);

    t.sendKey('ctrl+r');
    t.expect(['hello world']);
    for (let j = 0; j < 4; j++) {
      t.sendKey('ctrl+r');
    }
    t.expect(['hello wu']);

    t.sendKeys('0x');
    t.expect(['ello wu']);

    t.sendKeys('$x');
    t.expect(['ello w']);

    // delete on the last character should send the cursor back one
    t.sendKeys('hx');
    t.expect(['ellow']);

    t.sendKeys('Iy');
    t.sendKey('esc');
    t.expect(['yellow']);

    t.sendKeys('Ay');
    t.sendKey('esc');
    t.expect(['yellowy']);

    t.sendKeys('a purple');
    t.sendKey('esc');
    return t.expect(['yellowy purple']);
  });

  it("tests that redo doesn't go past latest", function() {
    let t = new TestCase(['thing']);
    t.sendKey('x');
    t.expect(['hing']);
    t.sendKeys('u');
    t.expect(['thing']);
    t.sendKey('ctrl+r');
    t.sendKey('ctrl+r');
    t.sendKey('ctrl+r');
    t.expect(['hing']);
    t.sendKeys('u');
    return t.expect(['thing']);
  });

  it("i + esc moves the cursor back a character, a + esc doesn't", function() {
    let t = new TestCase(['hello']);
    t.sendKey('$');
    // i + esc moves the cursor back a character
    for (let j = 0; j < 3; j++) {
      t.sendKey('i');
      t.sendKey('esc');
    }
    t.sendKeys('ra');
    t.expect(['hallo']);

    // a + esc doesn't
    for (let k = 0; k < 3; k++) {
      t.sendKey('a');
      t.sendKey('esc');
    }
    t.sendKeys('ru');
    return t.expect(['hullo']);
  });

  it('tests cursor behavior', function() {
    let t = new TestCase(['hello world']);

    // make sure delete and then undo doesn't move the cursor
    t.sendKeys('$hhxux');
    t.expect(['hello wold']);

    // delete on last character should work
    t.sendKeys('$dl');
    t.expect(['hello wol']);
    // and it should send the cursor back one
    t.sendKey('x');
    t.expect(['hello wo']);
    // replace
    t.sendKeys('ru');
    t.expect(['hello wu']);
    // undo and redo it
    t.sendKeys('u');
    t.expect(['hello wo']);
    t.sendKey('ctrl+r');
    t.expect(['hello wu']);
    // hitting left should send the cursor back one more
    t.sendKey('left');
    t.sendKeys('x');
    t.expect(['hello u']);

    t.sendKey('0');
    t.sendKey('right');
    t.sendKey('x');
    t.expect(['hllo u']);

    t.sendKeys('$c0ab');
    t.sendKey('esc');
    t.expect(['abu']);

    // does nothing
    t.sendKeys('dycy');
    return t.expect(['abu']);
  });

  it("tests the cursor doesn't go before line", function() {
    let t = new TestCase(['blahblah']);
    t.sendKeys('0d$iab');
    return t.expect(['ab']);
  });

  it('replaces with space properly', function() {
    let t = new TestCase(['space']);
    t.sendKeys(['f', 'a', 'r', 'space']);
    return t.expect(['sp ce']);
  });

  return it('replaces with number properly', function() {
    let t = new TestCase(['number']);
    t.sendKeys(['f', 'e', 'r', '3']);
    return t.expect(['numb3r']);
  });
});

describe('numbers (repeat next action)', function() {

  it('works on movement', function() {
    let t = new TestCase(['obladi oblada o lee lee o lah lah']);
    t.sendKeys('5lx');
    t.expect(['oblad oblada o lee lee o lah lah']);
    t.sendKeys('6wx');
    t.expect(['oblad oblada o lee lee o ah lah']);
    t.sendKeys('7$x');
    t.expect(['oblad oblada o lee lee o ah la']);
    t.sendKeys('5bx');
    t.expect(['oblad oblada o ee lee o ah la']);
    // numbers repeat works on c
    t.sendKeys('$5cb');
    t.sendKeys('blah blah blah');
    t.sendKey('esc');
    t.expect(['oblad oblada o blah blah blaha']);
    // numbers repeat works on d
    t.sendKeys('03de');
    t.expect([' blah blah blaha']);
    t.sendKeys('u');
    t.expect(['oblad oblada o blah blah blaha']);
    // number works within movement
    t.sendKeys('d3e');
    t.expect([' blah blah blaha']);
    // and undo does it all at once
    t.sendKeys('u');
    t.expect(['oblad oblada o blah blah blaha']);
    // try cut too
    t.sendKeys('c3eblah');
    t.sendKey('esc');
    return t.expect(['blah blah blah blaha']);
  });

  it('works on replace', function() {
    let t = new TestCase(['1234123412341234 is my credit card']);
    t.sendKeys('12r*');
    t.expect(['************1234 is my credit card']);
    t.sendKeys('l12X');
    t.expect(['1234 is my credit card']);
    // number repeat works with undo
    t.sendKeys('u');
    t.expect(['************1234 is my credit card']);
    t.sendKeys('u');
    t.expect(['1234123412341234 is my credit card']);
    t.sendKey('ctrl+r');
    t.expect(['************1234 is my credit card']);
    t.sendKeys('lX.................................');
    t.expect(['1234 is my credit card']);
    // number repeat works on undo
    t.sendKeys('8u');
    t.expect(['********1234 is my credit card']);
    t.sendKeys('6u');
    return t.expect(['1234123412341234 is my credit card']);
  });

  return it('replace character yanks', function() {
    let t = new TestCase(['yank']);
    t.sendKeys('st');
    t.sendKey('esc');
    t.expect(['tank']);
    t.sendKey('p');
    return t.expect(['tyank']);
  });
});

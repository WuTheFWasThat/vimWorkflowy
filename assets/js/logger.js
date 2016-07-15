/*
A straightforward class for configurable logging
Log-levels and streams (currently only one stream at a time)
*/

const LEVEL = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
  FATAL: 4
};

const STREAM = {
  STDOUT: 0,
  STDERR: 1,
  QUEUE: 2
};

class Logger {
  constructor(level=LEVEL.INFO, stream=STREAM.STDOUT) {
    this.setLevel(level);
    this.setStream(stream);

    let register_loglevel = (name, value) => {
      return this[name.toLowerCase()] = function() {
        if (this.level <= value) {
          return this.log.apply(this, arguments);
        }
      };
    };

    for (let name in LEVEL) {
      let value = LEVEL[name];
      register_loglevel(name, value);
    }
  }

  log() {
    if (this.stream === STREAM.STDOUT) {
      return console.log.apply(console, arguments);
    } else if (this.stream === STREAM.STDERR) {
      return console.error.apply(console, arguments);
    } else if (this.stream === STREAM.QUEUE) {
      return this.queue.push(arguments);
    }
  }

  setLevel(level) {
    return this.level = level;
  }

  off() {
    return this.level = Infinity;
  }

  setStream(stream) {
    this.stream = stream;
    if (this.stream === STREAM.QUEUE) {
      return this.queue = [];
    }
  }

  // for queue

  flush() {
    if (this.stream === STREAM.QUEUE) {
      for (let i = 0; i < this.queue.length; i++) {
        let args = this.queue[i];
        console.log.apply(console, args);
      }
      return this.empty();
    }
  }

  empty() {
    return this.queue = [];
  }
}

export { Logger };
export { LEVEL };
export { STREAM };

export let logger = new Logger(LEVEL.DEBUG);

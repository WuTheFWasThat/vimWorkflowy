# Guidelines to contributing

Just send a pull request.  Remember to write tests when appropriate!

For any questions, don't hesitate to contact me at [githubusername]@gmail.com.

I've marked a number of github issues with the label `small_task`, which could be good places to start.

## DEV SETUP: ##

For development, you'll probably want to run a web version of vimflowy locally.

#### INSTALL: ####

With recent versions of node/npm

    # Install git repo
    git clone https://github.com/WuTheFWasThat/vimflowy.git
    cd vimflowy

    # Install node modules
    npm install

    # Install typescript
    npm install tslint typescript typings -g
    # Install type definitions
    typings install

#### START: ####

Just run

    npm start

And you can visit the app at `http://localhost:3000/`

Assets will be automatically recompiled when the source changes, and tests are automatically re-ran.

Note that you may make new documents simply by visiting `http://localhost:3000/somedocumentname`

#### RUN TESTS: ####

Tests are run automatically with `npm start`.  To get a more detailed report, run

    npm test

And for a test coverage report, run

    npm run coverage

and visit `localhost:8080/coverage.html`

For profiling, you can use the browser, or run something like

    mocha --prof test/tests
    node-tick-processor *-v8.log > processed_log
    less processed_log

async = require 'async'
ExecutedModuleFinder = require './executed_module_finder'
fs = require 'fs-extra'
path = require 'path'
tmp = require 'tmp'


examples = [
  description: 'dependency not installed'
  expectedError: Error '''
    The following modules are listed in your `package.json` but are not installed.
      myModule
    All modules need to be installed to properly check for the usage of a module's executables.
    '''
  packages: [
    dir: '.'
    content:
      dependencies: {myModule: '0.0.1'}
  ]
,
  description: 'devDependency not installed'
  expectedError: Error '''
    The following modules are listed in your `package.json` but are not installed.
      myModule
    All modules need to be installed to properly check for the usage of a module's executables.
    '''
  packages: [
    dir: '.'
    content:
      devDependencies: {myModule: '0.0.1'}
  ]
,
  description: 'no scripts'
  expectedResult: []
  packages: [
    dir: '.'
    content: {}
  ]
,
  description: 'script using module exectuable'
  expectedResult: [name: 'myModule', script: 'test']
  packages: [
    dir: '.'
    content:
      dependencies: {myModule: '0.0.1'}
      scripts: {test: 'myExecutable --opt arg'}
  ,
    dir: 'node_modules/myModule'
    content:
      name: 'myModule'
      bin: {myExecutable: ''}
  ]
,
  description: 'script using scoped module exectuable'
  expectedResult: [name: '@myOrganization/myModule', script: 'test']
  packages: [
    dir: '.'
    content:
      dependencies: {'@myOrganization/myModule': '0.0.1'}
      scripts: {test: 'myExecutable --opt arg'}
  ,
    dir: 'node_modules/@myOrganization/myModule'
    content:
      name: '@myOrganization/myModule'
      bin: {myExecutable: ''}
  ]
]


describe 'ExecutedModuleFinder', ->
  beforeEach (done) ->
    tmp.dir {unsafeCleanup: true}, (err, @tmpDir) => done err

  describe 'find', ->
    examples.forEach ({description, expectedError, expectedResult, packages}) ->
      context description, ->
        beforeEach (done) ->
          async.series [
            (taskDone) =>
              writePackage = ({dir, content}, next) =>
                filePath = path.join @tmpDir, dir, 'package.json'
                fs.outputJson filePath, content, next
              async.each packages, writePackage, taskDone
            (taskDone) =>
              new ExecutedModuleFinder().find @tmpDir
                .stopOnError (@err) => taskDone()
                .toArray (@result) => taskDone()
          ], done

        if expectedError
          it 'returns the expected error', ->
            expect(@err).to.eql expectedError

        else
          it 'does not yield an error', ->
            expect(@err).to.not.exist

          it 'returns the expected error', ->
            expect(@result).to.eql expectedResult

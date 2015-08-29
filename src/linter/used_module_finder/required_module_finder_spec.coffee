getTmpDir = require '../../../spec/support/get_tmp_dir'
path = require 'path'
Promise = require 'bluebird'
RequiredModuleFinder = require './required_module_finder'

writeFile = Promise.promisify require('fs').writeFile


examples = [
  content: 'myModule = require "myModule'
  description: 'invalid coffeescript'
  expectedError: yes
  filePath: 'server.coffee'
,
  content: 'myModule = require "myModule"'
  description: 'coffeescript file requiring a module'
  expectedResult: [name: 'myModule', file: 'server.coffee']
  filePath: 'server.coffee'
,
  content: 'myModule = require.resolve "myModule"'
  description: 'coffeescript file resolving a module'
  expectedResult: [name: 'myModule', file: 'server.coffee']
  filePath: 'server.coffee'
,
  content: 'var myModule = require("myModule"'
  description: 'invalid javascript'
  expectedError: yes
  filePath: 'server.js'
,
  content: 'var myModule = require("myModule");'
  description: 'javascript file requiring a module'
  expectedResult: [name: 'myModule', file: 'server.js']
  filePath: 'server.js'
,
  content: 'var myModule = require.resolve("myModule");'
  description: 'javascript file resolving a module'
  expectedResult: [name: 'myModule', file: 'server.js']
  filePath: 'server.js'
]


describe 'RequiredModuleFinder', ->
  beforeEach ->
    @requiredModuleFinder = new RequiredModuleFinder {}
    getTmpDir().then (@tmpDir) =>

  describe 'find', ->
    examples.forEach ({content, description, expectedError, expectedResult, filePath}) ->
      context description, ->
        beforeEach ->
          writeFile path.join(@tmpDir, filePath), content

        if expectedError
          it 'rejects with a message that includes the file path', ->
            expect(@requiredModuleFinder.find(@tmpDir)).to.be.rejectedWith filePath
        else
          it 'resolves with the required modules', ->
            expect(@requiredModuleFinder.find(@tmpDir)).to.become expectedResult

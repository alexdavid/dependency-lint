_ = require 'lodash'
async = require 'async'
asyncHandlers = require 'async-handlers'
ExecutedModuleFinder = require './executed_module_finder'
RequiredModuleFinder = require './required_module_finder'


class UsedModuleFinder

  constructor: ({ignoreFilePatterns}) ->
    @executedModuleFinder = new ExecutedModuleFinder
    @requiredModuleFinder = new RequiredModuleFinder {ignoreFilePatterns}


  # Returns a highland stream of an array
  #   Each element is an object of the form {name, files, scripts}
  find: (dir, done) =>
    streams = [
      @requiredModuleFinder.find dir
      @executedModuleFinder.find dir
    ]
    highland.merge streams
      .reduce {}, @addFinding
      .flatMap _.values


  addFinding: (result, {name, file, script}) ->
    result[name] = {name, files: [], scripts: []} unless result[name]
    result[name].files.push file if file
    result[name].scripts.push script if script


module.exports = UsedModuleFinder

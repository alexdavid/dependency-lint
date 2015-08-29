_ = require 'lodash'
ExecutedModuleFinder = require './executed_module_finder'
highland = require 'highland'
RequiredModuleFinder = require './required_module_finder'


class UsedModuleFinder

  constructor: ({ignoreFilePatterns}) ->
    @executedModuleFinder = new ExecutedModuleFinder
    @requiredModuleFinder = new RequiredModuleFinder {ignoreFilePatterns}


  find: (dir, done) =>
    streams = [
      @requiredModuleFinder.find dir
      @executedModuleFinder.find dir
    ]
    highland.merge streams
      .reduce {}, @addFinding
      .flatMap _.values
      .stopOnError done
      .toArray (result) -> done null, result


  addFinding: (result, {name, file, script}) ->
    result[name] = {name, files: [], scripts: []} unless result[name]
    result[name].files.push file if file
    result[name].scripts.push script if script
    result


module.exports = UsedModuleFinder

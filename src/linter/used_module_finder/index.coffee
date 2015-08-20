_ = require 'lodash'
ExecutedModuleFinder = require './executed_module_finder'
Promise = require 'bluebird'
RequiredModuleFinder = require './required_module_finder'


class UsedModuleFinder

  constructor: ({ignoreFilePatterns}) ->
    @executedModuleFinder = new ExecutedModuleFinder
    @requiredModuleFinder = new RequiredModuleFinder {ignoreFilePatterns}


  find: (dir) =>
    Promise.resolve [@executedModuleFinder, @requiredModuleFinder]
      .map (finder) -> finder.find dir
      .then @normalizeModules


  normalizeModules: (modules...) ->
    result = {}
    for {name, file, script} in _.flattenDeep(modules)
      result[name] = {name, files: [], scripts: []} unless result[name]
      result[name].files.push file if file
      result[name].scripts.push script if script
    _.values result


module.exports = UsedModuleFinder

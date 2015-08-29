_ = require 'lodash'
async = require 'async'
asyncHandlers = require 'async-handlers'
fs = require 'fs'
globStream = require 'glob-stream'
highland = require 'highland'
ModuleNameParser = require './module_name_parser'
path = require 'path'


class ExecutedModulesFinder

  # Returns a highland stream of an array
  #   Each element is an object of the form {name, scripts}
  find: (dir) ->
    {scripts, dependencies, devDependencies} = require path.join(dir, 'package.json')
    scripts ?= {}
    modulesListed = _.keys(dependencies).concat _.keys(devDependencies)
    @getPackageJsonPaths(dir)
      .map @getModuleExecutables
      .collect()
      .tap (moduleExecutables) => @ensureAllModulesInstalled {moduleExecutables, modulesListed}
      .flatMap (moduleExecutables) => @parseModuleExecutables {moduleExecutables, scripts}


  ensureAllModulesInstalled: ({moduleExecutables, modulesListed}) ->
    modulesNotInstalled = _.difference modulesListed, _.map(moduleExecutables, 'name')
    return if modulesNotInstalled.length is 0
    throw Error """
      The following modules are listed in your `package.json` but are not installed.
        #{modulesNotInstalled.join '\n  '}
      All modules need to be installed to properly check for the usage of a module's executables.
      """


  findInScript: (script, moduleExecutables) ->
    result = []
    for {name, executables} in moduleExecutables
      for executable in executables
        continue if ModuleNameParser.isGlobalExecutable executable
        result.push name if script.match(executable) and name not in result
    result


  # Returns a highland stream of an array
  #   Each element is a path to a module's package.json
  getPackageJsonPaths: (dir) ->
    globs = ['*/package.json', '*/*/package.json']
    filenames = globStream.create globs, cwd: path.join(dir, 'node_modules')
    highland(filenames)
      .map (result) -> result.path


  getModuleExecutables: (packageJsonPath) ->
    {name, bin} = require packageJsonPath
    {name, executables: _.keys(bin)}



  parseModuleExecutables: ({moduleExecutables, scripts}) =>
    result = []
    for scriptName, script of scripts
      for name in @findInScript script, moduleExecutables
        result.push {name, script: scriptName}
    highland(result)


module.exports = ExecutedModulesFinder

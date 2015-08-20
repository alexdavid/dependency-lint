_ = require 'lodash'
async = require 'async'
asyncHandlers = require 'async-handlers'
fs = require 'fs'
globStream = require 'glob-stream'
ModuleNameParser = require './module_name_parser'
path = require 'path'


class ExecutedModulesFinder

  # Returns a highland stream of an array
  #   Each element is an object of the form {name, scripts}
  find: (dir, done) ->
    {scripts, dependencies, devDependencies} = require path.join(dir, 'package.json')
    scripts ?= {}
    modulesListed = _.keys(dependencies).concat _.keys(devDependencies)
    @getPackageJsonPaths
      .tap ensureModuleInstalled
      .map @getModuleExecutables
      .tap
    async.auto {
      packageJsons: (next) => @getModulePackageJsons dir, next
      moduleExecutables: ['packageJsons', (next, {packageJsons}) =>
        next null, @getModuleExecutables(packageJsons)
      ]
      ensureInstalled: ['moduleExecutables', (next, {moduleExecutables}) =>
        @ensureAllModulesInstalled {modulesListed, moduleExecutables}, next
      ]
      formattedExecutables: ['moduleExecutables', (next, {moduleExecutables}) =>
        next null, @parseModuleExecutables({moduleExecutables, scripts})
      ]
    }, asyncHandlers.extract('formattedExecutables', done)


  ensureAllModulesInstalled: ({modulesListed, moduleExecutables}, done) ->
    modulesNotInstalled = _.difference modulesListed, _.keys(moduleExecutables)
    if modulesNotInstalled.length is 0
      done()
    else
      done new Error """
        The following modules are listed in your `package.json` but are not installed.
          #{modulesNotInstalled.join '\n  '}
        All modules need to be installed to properly check for the usage of a module's executables.
        """


  findInScript: (script, moduleExecutables) ->
    result = []
    for moduleName, executables of moduleExecutables
      for executable in executables
        continue if ModuleNameParser.isGlobalExecutable executable
        result.push moduleName if script.match(executable) and moduleName not in result
    result


  # Returns a highland stream of an array
  #   Each element is a path to a module's package.json
  getPackageJsonPaths: (dir, done) ->
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
      for moduleName in @findInScript script, moduleExecutables
        result.push {name: moduleName, script: scriptName}
    result


module.exports = ExecutedModulesFinder

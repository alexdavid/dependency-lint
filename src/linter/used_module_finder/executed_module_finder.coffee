_ = require 'lodash'
async = require 'async'
asyncHandlers = require 'async-handlers'
{EventEmitter} = require 'events'
fs = require 'fs'
globStream = require 'glob-stream'
ModuleNameParser = require './module_name_parser'
path = require 'path'


class ExecutedModulesFinder extends EventEmitter

  constuctor: ({@dir}) ->
    {@scripts, dependencies, devDependencies} = require path.join(dir, 'package.json')
    @scripts = {} unless @scripts
    @modulesListed = _.keys(dependencies).concat _.keys(devDependencies)


  start: ->
    @ensureAllModulesInstalled ->
      fs.readdir path.join(dir, 'node_modules', 'bin/'), (err, files) ->
        if err then return @emit err
      globStream.create "*", cwd: path.join(dir, 'node_modules', 'bin/')
        .on 'data', @parsePackageJsonPath
        .on 'end', => @emit 'end'


  find: (dir, done) ->
    {scripts, dependencies, devDependencies} = require path.join(dir, 'package.json')
    scripts = {} unless scripts
    callback = ([_, moduleExecutables]) => @findModuleExecutableUsage {moduleExecutables, scripts}
    async.parallel [
      (next) =>

        @ensureAllModulesInstalled {dir, modulesListed}, next
      (next) =>
        @getModuleExecutables dir, next
    ], asyncHandlers.transform(callback, done)


  ensureAllModulesInstalled: ({dir, modulesListed}, done) ->
    missing = []
    iterator = (moduleName, next) ->
      fs.access path.join(dir, 'node_modules', moduleName), (err) ->
        if err then missing.push moduleName
        next()
    callback = (err) ->
      if err then return @emit err
      if missing.length is 0 then return done()
      @emit new Error """
        The following modules are listed in your `package.json` but are not installed.
          #{missing.join '\n  '}
        All modules need to be installed to properly check for the usage of a module's executables.
        """
    async.each modulesListed, iterator, callback


  findInScript: (script, moduleExecutables) ->
    result = []
    for moduleName, executables of moduleExecutables
      for executable in executables
        continue if ModuleNameParser.isGlobalExecutable executable
        result.push moduleName if script.match(executable) and moduleName not in result
    result


  findModuleExecutableUsage: ({moduleExecutables, scripts}) =>
    result = []
    for scriptName, script of scripts
      for moduleName in @findInScript script, moduleExecutables
        result.push {name: moduleName, script: scriptName}
    result


  getModuleExecutables: (dir, done) ->
    async.auto {
      files: (next) -> glob "#{dir}/node_modules/.bin/*", next
      links: ['files', (next, {files}) -> async.map files, fs.readlink, next]
    }, asyncHandlers.transform(@parseModuleExecutables, done)


  parseModuleExecutables: ({files, links}) ->
    result = {}
    executables = files.map (file) -> path.basename file
    links.forEach (link, index) ->
      name = ModuleNameParser.stripSubpath path.relative('..', link)
      result[name] = [] unless result[name]
      result[name].push path.basename executables[index]
    result


module.exports = ExecutedModulesFinder

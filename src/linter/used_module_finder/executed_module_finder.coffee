_ = require 'lodash'
async = require 'async'
{EventEmitter} = require 'events'
fs = require 'fs'
ModuleNameParser = require './module_name_parser'
path = require 'path'


class ExecutedModulesFinder extends EventEmitter

  constructor: ({@dir}) ->
    @binPath = path.join @dir, 'node_modules', '.bin'
    packageJsonPath = path.join @dir, 'package.json'
    {@scripts, dependencies, devDependencies} = require packageJsonPath
    @scripts = {} unless @scripts
    @modulesListed = _.keys(dependencies).concat _.keys(devDependencies)


  start: ->
    @ensureAllModulesInstalled =>
      @getModuleExecutables (err, executables) =>
        if err then return @emit 'error', err
        async.each executables, @parseExecutable, => @emit 'done'


  # Checks if all listed modules are installed
  ensureAllModulesInstalled: (done) ->
    missing = []
    iterator = (moduleName, next) =>
      fs.access path.join(@dir, 'node_modules', moduleName), (err) ->
        if err then missing.push moduleName
        next()
    callback = (err) =>
      if err then return @emit 'error', err
      if missing.length is 0 then return done()
      @emit 'error', Error """
        The following modules are listed in your `package.json` but are not installed.
          #{missing.join '\n  '}
        All modules need to be installed to properly check for the usage of a module's executables.
        """
    async.each @modulesListed, iterator, callback


  # Returns an array of scripts the executable is used in
  findScriptUsage: (executable) ->
    Object.keys(@scripts).filter (key) => @scripts[key].match executable


  # Returns an array of the module executables
  getModuleExecutables: (done) ->
    fs.access @binPath, (err) =>
      if err then done null, []
      fs.readdir @binPath, done


  # Parse an executable, emits a data event for each script its used in
  parseExecutable: (executable, done) =>
    if ModuleNameParser.isGlobalExecutable executable then return done()
    scripts = @findScriptUsage executable
    if scripts.length is 0 then return done()
    fs.readlink path.join(@binPath, executable), (err, relativePath) =>
      if err then return @emit 'error', err
      name = ModuleNameParser.stripSubpath path.relative('..', relativePath)
      scripts.forEach (script) => @emit 'data', {name, script}
      done()


module.exports = ExecutedModulesFinder

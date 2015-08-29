_ = require 'lodash'
async = require 'async'
asyncHandlers = require 'async-handlers'
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
    async.waterfall [
      (next) =>
        @ensureAllModulesInstalled next
      (next) =>
        fs.access @binPath, (err) =>
          if err then next null, []
          fs.readdir @binPath, next
      (executables, next) =>
        async.each executables, @parseExecutable, next
    ], (err) =>
      if err then return @emit 'error', err
      @emit 'done'


  # Parse an executable, emits a data event for each script its used in
  parseExecutable: (executable, done) =>
    if ModuleNameParser.isGlobalExecutable executable then return done()
    scripts = @findScriptUsage executable
    if scripts.length is 0 then return done()
    fs.readlink path.join(@binPath, executable), (err, relativePath) =>
      if err then return done err
      name = ModuleNameParser.stripSubpath path.relative('..', relativePath)
      scripts.forEach (script) => @emit 'data', {name, script}
      done()


  # Returns an array of scripts the executable is used in
  findScriptUsage: (executable) ->
    Object.keys(@scripts).filter (key) => @scripts[key].match executable


  # Checks if all listed modules are installed
  ensureAllModulesInstalled: (done) ->
    missing = []
    iterator = (moduleName, next) =>
      fs.access path.join(@dir, 'node_modules', moduleName), (err) ->
        if err then missing.push moduleName
        next()
    callback = (err) =>
      if err then return done err
      if missing.length is 0 then return done()
      done Error """
        The following modules are listed in your `package.json` but are not installed.
          #{missing.join '\n  '}
        All modules need to be installed to properly check for the usage of a module's executables.
        """
    async.each @modulesListed, iterator, callback


module.exports = ExecutedModulesFinder

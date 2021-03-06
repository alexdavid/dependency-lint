_ = require 'lodash'
async = require 'async'
asyncHandlers = require 'async-handlers'
extensions = require './supported_file_extensions'
fs = require 'fs'
fsExtra = require 'fs-extra'
path = require 'path'
yaml = require 'js-yaml'

require 'coffee-script/register'
require 'fs-cson/register'


class ConfigurationLoader

  defaultConfigPath: path.join __dirname, '..', '..', 'config', 'default.json'


  load: (dir, done) ->
    merge = (args) -> _.assign {}, args...
    async.parallel [
      @loadDefaultConfig
      (next) => @loadUserConfig dir, next
    ], asyncHandlers.transform(merge, done)


  loadConfig: (filePath, done) =>
    return done() unless filePath
    handler = asyncHandlers.prependToError filePath, done
    switch path.extname filePath
      when '.coffee', '.cson', '.js', '.json'
        @toAsync (-> require filePath), handler
      when '.yml', '.yaml'
        async.waterfall [
          (next) -> fs.readFile filePath, 'utf8', next
          (content, next) => @toAsync (-> yaml.safeLoad content), next
        ], handler


  loadDefaultConfig: (done) =>
    fsExtra.readJson @defaultConfigPath, done


  loadUserConfig: (dir, done) =>
    filePaths = _.map extensions, (ext) -> path.join dir, "dependency-lint.#{ext}"
    async.waterfall [
      (next) -> async.detect filePaths, fs.exists, (result) -> next null, result
      @loadConfig
    ], done


  toAsync: (fn, done) ->
    try
      result = fn()
    catch err
      done err
    done null, result


module.exports = ConfigurationLoader

_ = require 'lodash'
extensions = require './supported_file_extensions'
fs = require 'fs'
highland = require 'highland'
path = require 'path'
prependToError = require '../util/prepend_to_error'
yaml = require 'js-yaml'

require 'coffee-script/register'
require 'fs-cson/register'


class ConfigurationLoader

  defaultConfigPath: path.join __dirname, '..', '..', 'config', 'default.json'


  load: (dir) ->
    @getDefaultConfig()
      .concat @getUserConfig(dir)
      .reduce {}, _.assign


  # Returns a stream containing the config as pairs
  getConfig: (filePath) =>
    stream = switch path.extname filePath
      when '.coffee', '.cson', '.js', '.json'
        highland([filePath]).map require
      when '.yml', '.yaml'
        highland.wrapCallback(fs.readFile)(filePath, 'utf8')
          .reduce '', (x, y) -> x + y
          .map yaml.safeLoad

    stream.errors (err, push) ->
      prependToError err, filePath
      push err


  # Returns a stream containing the default config as pairs
  getDefaultConfig: =>
    highland [require @defaultConfigPath]


  # Returns a stream containing the user config as pairs
  getUserConfig: (dir) =>
    highland extensions
      .map (ext) -> path.join dir, "dependency-lint.#{ext}"
      .flatFilter (filePath) ->
        highland (push) ->
          fs.exists filePath, (exists) ->
            push null, exists
            push null, highland.nil
      .take 1
      .flatMap @getConfig


module.exports = ConfigurationLoader

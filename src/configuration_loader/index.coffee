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


  # Returns a highland stream with one element - the config found as an object
  load: (dir) ->
    @getDefaultConfig()
      .concat @getUserConfig(dir)
      .reduce {}, _.assign


  # Returns a highland stream with one element - the config found at filePath as an object
  getConfig: (filePath) =>
    stream = switch path.extname filePath
      when '.coffee', '.cson', '.js', '.json'
        highland([filePath]).map require
      when '.yml', '.yaml'
        highland.wrapCallback(fs.readFile)(filePath, 'utf8')
          .collect()
          .map yaml.safeLoad

    stream.errors (err, push) ->
      prependToError err, filePath
      push err


  # Returns a highland stream with one element - the default config as an object
  getDefaultConfig: =>
    highland [require @defaultConfigPath]


  # Returns a highland stream with one or no elements - the user config as an object
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

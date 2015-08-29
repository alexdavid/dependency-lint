_ = require 'lodash'
coffeeScript = require 'coffee-script'
detective = require 'detective'
ModuleNameParser = require './module_name_parser'
path = require 'path'
prependToError = require '../../util/prepend_to_error'
Promise = require 'bluebird'

readFile = Promise.promisify require('fs').readFile
glob = Promise.promisify require('glob')


class RequiredModuleFinder

  constructor: ({@ignoreFilePatterns}) ->


  find: (dir) ->
    glob '**/*.{coffee,js}', cwd: dir, ignore: @ignoreFilePatterns
      .map (filePath) => @findInFile {dir, filePath}
      .then _.flatten


  findInFile: ({dir, filePath}) ->
    readFile path.join(dir, filePath), 'utf8'
      .then (content) => @compile {content, filePath}
      .then (content) => detective content, {@isRequire}
      .then (moduleNames) => @normalizeModuleNames {filePath, moduleNames}
      .catch prependToError filePath


  compile: ({content, filePath}) ->
    if path.extname(filePath) is '.coffee'
      coffeeScript.compile content, filename: filePath
    else
      content


  isRequire: ({type, callee}) ->
    type is 'CallExpression' and
      ((callee.type is 'Identifier' and
        callee.name is 'require') or
       (callee.type is 'MemberExpression' and
        callee.object.type is 'Identifier' and
        callee.object.name is 'require' and
        callee.property.type is 'Identifier' and
        callee.property.name is 'resolve'))


  normalizeModuleNames: ({filePath, moduleNames}) ->
    _.chain moduleNames
      .reject ModuleNameParser.isBuiltIn
      .reject ModuleNameParser.isRelative
      .map ModuleNameParser.stripSubpath
      .map (name) -> {name, file: filePath}
      .value()


module.exports = RequiredModuleFinder

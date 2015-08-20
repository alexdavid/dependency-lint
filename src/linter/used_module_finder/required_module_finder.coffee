_ = require 'lodash'
async = require 'async'
coffeeScript = require 'coffee-script'
detective = require 'detective'
globStream = require 'glob-stream'
highland = require 'highland'
fs = require 'fs'
ModuleNameParser = require './module_name_parser'
path = require 'path'


class RequiredModuleFinder

  constructor: ({@ignoreFilePatterns}) ->


  # Returns a highland stream of an array
  #   Each element is an object of the form {name, file}
  find: (dir, done) ->
    filenames = globStream.create '**/*.{coffee,js}', {cwd: dir, ignore: @ignoreFilePatterns}
    highland(filenames).flatMap @findInFile


  findInFile: ({base, path: filePath}) =>
    highland fs.createReadStream(filePath, encoding: 'utf8')
      .map (content) => @compile {content, filePath} # BETTER: streaming coffeescript compiling
      .flatMap (content) => @findInContent {content, filePath}
      .map (result) ->
        result.file = path.relative base, filePath
        result


  compile: ({content, filePath}) ->
    if path.extname(filePath) is '.coffee'
      coffeeScript.compile content, filename: filePath
    else
      content


  findInContent: ({content, filePath}) ->
    moduleNames = detective content, {@isRequire} # BETTER: streaming AST walking
    highland(moduleNames)
      .reject ModuleNameParser.isBuiltIn
      .reject ModuleNameParser.isRelative
      .map ModuleNameParser.stripSubpath
      .map (name) -> {name, file: filePath}


  isRequire: ({type, callee}) ->
    type is 'CallExpression' and
      ((callee.type is 'Identifier' and
        callee.name is 'require') or
       (callee.type is 'MemberExpression' and
        callee.object.type is 'Identifier' and
        callee.object.name is 'require' and
        callee.property.type is 'Identifier' and
        callee.property.name is 'resolve'))


module.exports = RequiredModuleFinder

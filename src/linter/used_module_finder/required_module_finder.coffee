_ = require 'lodash'
async = require 'async'
coffeeScript = require 'coffee-script'
detective = require 'detective'
globStream = require 'glob-stream'
glob = require 'glob'
fs = require 'fs'
ModuleFilterer = require './module_filterer'
path = require 'path'


class RequiredModuleFinder

  constructor: ({@ignoreFilePatterns}) ->


  # Returns a highland stream of an array
  #   Each element is an object of the form {name, file}
  find: (dir, done) ->
    filenames = globStream.create '**/*.{coffee,js}', {cwd: dir, ignore: @ignoreFilePatterns}
    highland(filenames).flatMap (filePath) => @findInFile {dir, filePath}


  findInFile: ({dir, filePath}) ->
    highland fs.createReadStream(path.join(dir, filePath), encoding: 'utf8')
      .collect()
      .map (content) => @compile {content, filePath} # BETTER: streaming coffeescript compiling
      .flatMap (content) => @findInContent {content, filePath}


  compile: ({content, filePath}) ->
    if path.extname(filePath) is '.coffee'
      coffeeScript.compile content, filename: filePath
    else
      content


  findInContent: ({content, filePath}) ->
    moduleNames = detective content, {@isRequire} # BETTER: streaming AST walking
    moduleNames = ModuleFilterer.filterRequiredModules moduleNames
    highland(moduleNames)
      .filter ModuleNameParser.isRelativeModule
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

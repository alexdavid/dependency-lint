(function() {
  var DependencyLinter, Linter, ListedModuleFinder, UsedModuleFinder, async, asyncHandlers;

  async = require('async');

  asyncHandlers = require('async-handlers');

  DependencyLinter = require('./dependency_linter');

  ListedModuleFinder = require('./listed_module_finder');

  UsedModuleFinder = require('./used_module_finder');

  Linter = (function() {
    function Linter(arg) {
      var allowUnused, devFilePatterns, devScripts, ignoreFilePatterns;
      allowUnused = arg.allowUnused, devFilePatterns = arg.devFilePatterns, devScripts = arg.devScripts, ignoreFilePatterns = arg.ignoreFilePatterns;
      this.dependencyLinter = new DependencyLinter({
        allowUnused: allowUnused,
        devFilePatterns: devFilePatterns,
        devScripts: devScripts
      });
      this.listedModuleFinder = new ListedModuleFinder;
      this.usedModuleFinder = new UsedModuleFinder({
        ignoreFilePatterns: ignoreFilePatterns
      });
    }

    Linter.prototype.lint = function(dir, done) {
      return async.parallel({
        listedModules: (function(_this) {
          return function(next) {
            return _this.listedModuleFinder.find(dir, next);
          };
        })(this),
        usedModules: (function(_this) {
          return function(next) {
            return _this.usedModuleFinder.find(dir, next);
          };
        })(this)
      }, asyncHandlers.transform(this.dependencyLinter.lint, done));
    };

    return Linter;

  })();

  module.exports = Linter;

}).call(this);

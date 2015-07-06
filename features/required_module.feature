Feature: Required module

  As a developer requiring a module listed in my package.json
  I want it to be reported as passing


  Scenario: dependency
    Given I have "express" installed
    And I have "express" listed as a dependency
    And I have a file "server.coffee" which requires "express"
    When I run "dependency-lint"
    Then I see the output
      """
      dependencies:
        ✓ express

      ✓ 0 errors
      """


  Scenario: devDependency
    Given I have "chai" installed
    And I have "chai" listed as a devDependency
    And I have a file "server_spec.coffee" which requires "chai"
    When I run "dependency-lint"
    Then I see the output
      """
      devDependencies:
        ✓ chai

      ✓ 0 errors
      """

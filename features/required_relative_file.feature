Feature: Required module: relative file

  As a developer requiring a relative file
  I don't want it to be reported as a missing module


  Scenario: dependency
    Given I have no dependencies listed
    And I have a file "server.coffee" which requires "./helper"
    When I run "dependency-lint"
    Then I see the output
      """
      ✓ 0 errors
      """


  Scenario: devDependency
    Given I have no devDependencies listed
    And I have a file "server_spec.coffee" which requires "./helper"
    When I run "dependency-lint"
    Then I see the output
      """
      ✓ 0 errors
      """

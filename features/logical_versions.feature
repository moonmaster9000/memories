Feature: Logical Version Numbers
  As a programmer
  When I soft revert a document to a previous version
  I want to know what the logical version number and revision is
  
  Scenario: Soft reverting a document should set the logical version and revision
    Given a document with versions
    When I soft revert that document to a previous version
    And I call #logical_revision
    Then I should receive the revision of that previous version
    When I call #logical_version_number
    Then I should receive the version number of that previous version
    When I save
    Then the logical revision should equal the actual revision
    And the logical version number should equal the actual version number
    

Feature: Easily accessing previous versions

  Scenario: The "versions" method should return a versions array proxy
    Given a document with versions
    When I call the "versions" method
    Then I should get back an array proxy for previous versions

  Scenario: The "versions" array proxy should accept an integer
    Given a "versions" array proxy for a document
    When I call the [] method on the proxy with an integer that corresponds to an existing version
    Then I should get back a version proxy for that version of the document
    When I call the [] method on the proxy with an integer that does not correspond to a version
    Then I should get back nil

  Scenario: The "versions" array proxy should accept a string
    Given a "versions" array proxy for a document
    When I call the [] method on the proxy with a string corresponding to a valid version
    Then I should get back a version proxy for that version of the document
    When I call the [] method on the proxy with a string that does not correspond to a valid version
    Then I should get back nil

  Scenario: The "versions" array proxy accessed with a range that contains only valid versions
    Given a "versions" array proxy for a document
    When I call the [] method on the proxy with a range of valid versions
    Then I should get back an array consisting of those valid versions
    
  Scenario: The "versions" array proxy accessed with a range that includes invalid versions
    Given a "versions" array proxy for a document
    When I call the [] method on the proxy with a range that includes versions that don't exist
    Then I should get back an array containing the versions that existed

  Scenario: The "versions" array proxy accessed with a range that includes no valid versions
    Given a "versions" array proxy for a document
    When I call the [] method on the proxy with a range that does not include any valid versions
    Then I should get back nil

  Scenario: The "versions" array proxy should return the latest version of the document when requested
    Given a "versions" array proxy for a document
    When I call the #last method on the proxy
    Then I should get a version proxy for the latest version of the document
    When I update the document
    And I call the #last method on the proxy
    Then I should get a version proxy for the latest version of the document

  Scenario: The #version method on a version proxy should return the complete revision number associated with that version
    Given a "versions" array proxy for a document
    When I access a version proxy within the #versions array proxy
    And I call the #version method on the proxy
    Then I should receive the revision number for that version

  Scenario: The #version_number method on a version proxy should return the version number associated with that version
    Given a "versions" array proxy for a document
    When I access a version proxy within the #versions array proxy
    And I call the #version_number method on the proxy
    Then I should receive the version number for that version

  Scenario: The #milestone? method on a version proxy should return true if that version is a milestone, false otherwise
    Given a "versions" array proxy for a document with milestones
    When I access a version proxy within the #versions array proxy that happens to be a milestone
    And I call the #milestone? method on the proxy
    Then I should receive true
    When I access a version proxy within the #versions array proxy that is not a milestone
    And I call the #milestone? method on the proxy
    Then I should receive false
    
  Scenario: The #instance method on a version proxy should return the actual version document instance
    Given a "versions" array proxy for a document
    When I access a version proxy within the #versions array proxy
    And I call the #instance method on the proxy
    Then I should receive the instance corresponding to that version of the document

  Scenario: Iterating through all versions
    Given a "versions" array proxy for a document
    When I call the #each method with a block
    Then I should be able to iterate through all versions of the document
  
  Scenario: Setting the correct updated_at when accessing versions
    Given a document with versions and timestamps
    When I access the "updated_at" property for current version
    Then I should get the correct "updated_at" value
    When I access the "updated_at" property for version 2
    Then I should get the correct "updated_at" value

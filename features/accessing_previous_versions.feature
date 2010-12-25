Feature: Easily accessing previous versions

  Scenario: The "versions" method should return a versions array proxy
    Given a document with versions
    When I call the "versions" method
    Then I should get back an array proxy for previous versions

  Scenario: The "versions" array proxy should accept an integer
    Given a "versions" array proxy for a document
    When I call the [] method on the proxy with an integer that corresponds to an existing version
    Then I should get back that version of the document
    When I call the [] method on the proxy with an integer that does not correspond to a version
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
    Then I should get back an empty array

  Scenario: The "versions" array proxy should accept a string
    Given a "versions" array proxy for a document
    When I call the [] method on the proxy with a string corresponding to a valid version
    Then I should get back that version of the document
    When I call the [] method on the proxy with an string that does not correspond to a valid version
    Then I should get back nil

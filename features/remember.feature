Feature: Version specified properties. 

  @focus
  Scenario: Only versioning certain properties in a document
    When I create a class that uses the #remember method
    Then only the properties specified in #remember should be versioned

  Scenario: Trying to use both #remember and #forget
    When I create a class that tries to use both #remember and #forget
    Then the Memories library should throw an exception.

Feature: Don't version (i.e., forget) certain properties. 

  Scenario: Not versioning notes on a book.
    Given there is a book class with a notes property
    When I create new versions of a book
    Then the notes should not be versioned

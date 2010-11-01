Feature: Version attachments
  As a software engineer 
  I want to be able to version attachments on a document
  So that I can rollback attachments on a document to a previous state

  @focus
  Scenario: Versioning all document attachments
    When I create a class that calls the remember_attachments! method
    Then all attachments should be versioned by Memories

  Scenario: Versioning specific document attachments
    When I create a class that calls the remember_attachments! method with strings and regexes
    Then all attachments with names matching any of those strings and regexes should be versioned by Memories

  Scenario: Reverting to a state with fewer attachments
    Given a document that versions attachments
    And the first version of the document has no attachments
    And the next version of the document has "1" attachment
    And the next version of the document has "2" attachments
    When I revert the document to the first version
    Then the document should have no attachments
    When I revert the document to the second version
    Then the document should have "1" attachment
    When I revert the document to the third version
    Then the document should have "2" attachments

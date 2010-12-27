Feature: Which attachments to remember, and which to forget
  
  Scenario: Returning a list of attachments to remember
    Given a document model that remembers attachments with the word "attachment" in the name
    And a document that has attachments "attachment 1", "unversioned attached asset", "versioned attachment 2"
    When I call the #attachments_to_remember method
    Then "attachment 1" should be in the list
    And "versioned attachment 2" should be in the list
    But "unversioned attached asset" should not be in the list

  Scenario: Returning a list of attachments to remember
    Given a document model that remembers attachments with the word "attachment" in the name
    And a document that has attachments "attachment 1", "unversioned attached asset", "versioned attachment 2"
    When I call the #attachments_to_forget method
    Then "attachment 1" should not be in the list
    And "versioned attachment 2" should not be in the list
    But "unversioned attached asset" should be in the list

Feature: Going back in time should restore attachments

  Scenario: 
    Given a document with no attachments
    When I add an attachment "attachment1"
    And I save
    And I add an attachment "attachment2"
    And I save
    When I revert to version "2"
    Then I should be able to access "attachment1"
    When I revert to version "3"
    Then I should be able to access "attachment1"
    And I should be able to access "attachment2"

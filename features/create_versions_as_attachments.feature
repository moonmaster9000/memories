Feature: Create Versions as Attachments

  Scenario: Versions created on update, not create
    When I create a new document
    Then that document should not have any versions
    When I update that document
    Then the properties of the previous version should be saved as an attachment

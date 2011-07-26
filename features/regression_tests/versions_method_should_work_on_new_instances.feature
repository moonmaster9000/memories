Feature: The "versions" instance method should not raise an exception on new instances
  Basically, "my_doc.versions.*" should work even if "my_doc" isn't saved

  Scenario: New instance
    Given an unsaved instance of a document that includes Memories
    When I call the "versions.count" on that instance
    Then I should get 0

Feature: Marking versions as milestones

  Scenario: Mark it as a milestone
    Given I have a document
    When I mark that document as a milestone
    Then that revision should show up as the newest milestone

  @focus
  Scenario: #milestone? method
    Given I have a document with 5 milestones
    And the current version is not a milestone
    When I call the #milestone? method
    Then I should receive false
    When I soft revert the document to one of those milestones
    And I call the #milestone? method
    Then I should receive true
    When I soft revert the document to a version right after a milestone
    And I call the #milestone? method
    Then I should receive false

  @focus
  Scenario: #milestone_commit? method
    Given I have a document with 5 milestones
    When I soft revert the document to a version right after a milestone
    And I call the #milestone_commit? method
    Then I should receive true
    When I soft revert the document to one of those milestones
    And I call the #milestone_commit? method
    Then I should receive false

  Scenario: Annotating a milestone
    Given I have a document
    When I mark that document as a milestone with an annotation
    Then I should be able to retrieve that annotation from the milestone properties
    When I re-retrieve that document from the database
    Then I should be able to retrieve that annotation from the milestone properties
 
  
  Scenario: Accessing the milestone version data
    Given I have a document
    When I mark that document as a milestone
    And I access the #instance property on the latest milestone
    Then it should return the version corresponding to that milestone
    When I create another milestone
    Then I should be able to access the data for both milestones

  Scenario Outline: Reverting to a milestone
    Given I have a document with 5 milestones 
    When I revert the document to milestone <num>
    Then the document should contain the properties of milestone <num>

    Examples:
      |num|
      |1|
      |2|
      |3|
      |4|
      |5|
    

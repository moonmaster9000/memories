Feature: Marking versions as milestones

  Scenario: Mark it as a milestone
    Given I have a document
    When I mark that document as a milestone
    Then that revision should show up as the newest milestone
  
  @focus
  Scenario: Annotating a milestone
    Given I have a document
    When I mark that document as a milestone with an annotation
    Then I should be able to retrieve that annotation from the milestone properties
    When I re-retrieve that document from the database
    Then I should be able to retrieve that annotation from the milestone properties
 
  
  @focus
  Scenario: Accessing the milestone version data
    Given I have a document
    When I mark that document as a milestone
    And I access the #data property on the latest milestone
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
    

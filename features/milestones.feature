Feature: Marking versions as milestones

  Scenario: Mark it as a milestone
    Given I have a document
    When I mark that document as a milestone
    Then that revision should show up as the newest milestone

  Scenario: Annotating a milestone
    Given I have a document
    When I mark that document as a milestone with an annotation
    Then I should be able to retrieve that annotation from the milestone properties

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
    

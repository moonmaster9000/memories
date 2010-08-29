Feature: Revert to previous versions

  Scenario Outline: Revert to any previous version
    Given I have 5 versions of a document
    When I revert the document to version <num>
    Then the document should contain the properties of version <num>

    Examples:
      | num  |
      |  1   |
      |  2   |
      |  3   |
      |  4   |

  # Soft revert is reverting without saving. i.e., updating the properties of the object in memory, but
  # not persisting to the database.
  Scenario Outline: Soft Revert to any previous version
    Given I have 5 versions of a document
    When I soft revert the document to version <num>
    Then the unsaved document should contain the properties of version <num>

    Examples:
      | num  |
      |  1   |
      |  2   |
      |  3   |
      |  4   |



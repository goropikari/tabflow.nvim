Feature: Smart Labels
  As a user with many buffers open
  I want to distinguish between buffers with the same filename
  So that I don't get confused between different files

  Background:
    Given I have tabflow.nvim installed

  Scenario: Disambiguating duplicate filenames with parent directory
    Given I have 2 buffers with same filename:
      | path                     |
      | /home/user/project/a/file.lua |
      | /home/user/project/b/file.lua |
    When I view the tabline labels
    Then the first buffer should be labeled "a/file.lua"
    And the second buffer should be labeled "b/file.lua"

  Scenario: Showing only filename when unique
    Given I have 2 buffers:
      | path                     |
      | /home/user/project/a/x.lua |
      | /home/user/project/b/y.lua |
    When I view the tabline labels
    Then the first buffer should be labeled "x.lua"
    And the second buffer should be labeled "y.lua"

  Scenario: Handling buffers with no name
    Given I have a new buffer with no path
    When I view the tabline labels
    Then the buffer should be labeled "[No Name]"

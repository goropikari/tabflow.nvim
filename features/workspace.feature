Feature: Workspace and Buffer Management
  As a Neovim user
  I want to manage my buffers within workspaces (tabs)
  So that I can group related files together

  Background:
    Given I have tabflow.nvim configured

  Scenario: Creating a new workspace
    When I execute the command ":TabflowNewTab"
    Then a new tabpage should be created
    And it should be empty and in "buffers" mode

  Scenario: Adding a buffer to the current workspace
    Given I have a new buffer open
    When I edit a file "my_file.lua"
    Then "my_file.lua" should be added to the current workspace's buffer list

  Scenario: Removing a buffer from the current workspace
    Given the current workspace has 2 buffers: "a.lua", "b.lua"
    When I am on buffer "a.lua"
    And I execute the command ":TabflowCloseBuffer"
    Then "a.lua" should be removed from the current workspace
    And "b.lua" should become the active buffer

  Scenario: Renaming a workspace
    Given I am on the first tabpage
    When I execute the command ":TabflowRenameTab Research"
    Then the tab name should be "Research"

  Scenario: Closing a workspace
    Given I have 2 tabpages
    When I execute the command ":TabflowCloseTab"
    Then the current tabpage should be closed
    And I should be on the remaining tabpage

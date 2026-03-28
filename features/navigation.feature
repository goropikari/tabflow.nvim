Feature: Tab and Buffer Navigation
  As a Neovim user
  I want a hierarchical interactive UI for tabs and buffers
  So that I can manage my workspaces and files efficiently

  Background:
    Given I have Neovim open with tabflow.nvim installed

  Scenario: Toggling between Tab mode and Buffer mode
    When I execute the command ":TabflowToggleMode"
    Then the navigation mode should switch from "buffers" to "tabs"
    When I execute the command ":TabflowToggleMode" again
    Then the navigation mode should switch back to "buffers"

  Scenario: Explicitly switching to Tab mode
    Given the current mode is "buffers"
    When I execute the command ":TabflowTabsMode"
    Then the navigation mode should be "tabs"

  Scenario: Explicitly switching to Buffer mode
    Given the current mode is "tabs"
    When I execute the command ":TabflowBuffersMode"
    Then the navigation mode should be "buffers"

  Scenario: Navigating between tabs
    Given I have 3 tabpages
    And I am on the first tabpage
    When I execute the command ":TabflowNextTab"
    Then I should be on the second tabpage
    When I execute the command ":TabflowNextTab" again
    Then I should be on the third tabpage
    When I execute the command ":TabflowNextTab" again
    Then I should be back on the first tabpage

  Scenario: Navigating between buffers in the current workspace
    Given the current tab has 3 buffers: "fileA.lua", "fileB.lua", "fileC.lua"
    And "fileA.lua" is active
    When I execute the command ":TabflowNextBuffer"
    Then "fileB.lua" should be the active buffer
    When I execute the command ":TabflowNextBuffer" again
    Then "fileC.lua" should be the active buffer
    When I execute the command ":TabflowNextBuffer" again
    Then "fileA.lua" should be the active buffer again

Feature: Mouse Interaction
  As a mouse-oriented user
  I want to interact with my tabs and buffers using clicks and drags
  So that I have an intuitive UI experience

  Background:
    Given I have a terminal with mouse support
    And tabflow.nvim is installed

  Scenario: Clicking a tab to switch
    Given the navigation mode is "tabs"
    When I left-click on the "Research" tab
    Then I should be switched to that tabpage
    And the navigation mode should switch to "buffers"

  Scenario: Middle-clicking to close an item
    Given I am in "tabs" mode
    When I middle-click on a tab
    Then that tabpage should be closed

  Scenario: Right-clicking a tab to rename
    Given I am in "tabs" mode
    When I right-click on a tab
    Then a prompt should appear to rename that tab

  Scenario: Dragging to reorder tabs
    Given I have 3 tabs: "Tab 1", "Tab 2", "Tab 3"
    When I drag "Tab 1" and drop it after "Tab 2"
    Then the order of tabs should be: "Tab 2", "Tab 1", "Tab 3"

  Scenario: Moving a buffer between workspaces
    Given I have 2 tabs: "Research", "Project"
    And "Research" tab has buffer "notes.md"
    When I drag "notes.md" from "Research" and drop it onto the "Project" tab
    Then "notes.md" should be removed from the "Research" workspace
    And "notes.md" should be added to the "Project" workspace

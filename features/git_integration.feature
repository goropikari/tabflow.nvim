Feature: Git Integration
  As a developer using git
  I want my workspace names to reflect my git branch and worktrees
  So that I can easily switch context between branches

  Background:
    Given I have a git repository initialized
    And I have tabflow.nvim configured

  Scenario: Automatic tab naming from git branch
    Given the current git branch is "feature-login"
    When I create a new tabpage with ":TabflowNewTab"
    Then the new tab name should be "feature-login"

  Scenario: Manually setting tab name to git branch
    Given the current git branch is "bugfix/123"
    And the current tab name is "Research"
    When I execute the command ":TabflowSetGitBranchName"
    Then the tab name should change to "bugfix/123"

  Scenario: Opening a git worktree in a new tab
    Given a git worktree exists for branch "dev" at "/path/to/worktree"
    When I execute the command ":TabflowOpenWorktree dev"
    Then a new tabpage should be created
    And the tab local directory (tcd) should be "/path/to/worktree"
    And the tab name should be "dev"

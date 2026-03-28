local state = require('tabflow.state')

describe('tabflow.git', function()
  local old_system = vim.fn.system
  local mock_git_branch = ''
  local mock_git_root = ''
  local mock_git_worktrees = ''

  before_each(function()
    state.state.tabs = {}
    mock_git_branch = ''
    mock_git_root = ''
    mock_git_worktrees = ''

    -- Mock vim.fn.system to simulate git commands
    vim.fn.system = function(cmd)
      if type(cmd) == 'table' then
        cmd = table.concat(cmd, ' ')
      end
      if cmd:match('rev%-parse %-%-show%-toplevel') then
        return mock_git_root .. '\n'
      elseif cmd:match('symbolic%-ref %-%-short HEAD') then
        return mock_git_branch .. '\n'
      elseif cmd:match('worktree list') then
        return mock_git_worktrees .. '\n'
      end
      return ''
    end
  end)

  after_each(function()
    vim.fn.system = old_system
  end)

  it('automatically sets tab name from git branch when ensuring tab', function()
    mock_git_root = '/path/to/repo'
    mock_git_branch = 'feature-xyz'

    local tab = vim.api.nvim_get_current_tabpage()
    state.ensure_tab(tab)

    assert.are.equal('feature-xyz', state.get_tab_name(tab))
  end)

  it('can set tab name to git branch manually', function()
    mock_git_root = '/path/to/repo'
    mock_git_branch = 'bugfix-123'

    local tab = vim.api.nvim_get_current_tabpage()
    state.set_tab_name_to_git_branch(tab)

    assert.are.equal('bugfix-123', state.get_tab_name(tab))
  end)

  it('can list git worktrees', function()
    mock_git_root = '/path/to/repo'
    mock_git_worktrees = '/path/to/repo/main abc123 [main]\n/path/to/repo/dev def456 [dev]'

    local worktrees = state.get_git_worktrees()

    assert.are.equal(2, #worktrees)
    assert.are.equal('main', worktrees[1].branch)
    assert.are.equal('dev', worktrees[2].branch)
  end)
end)

local M = {}

function M.setup(opts)
  -- Options could be handled here in the future

  require('tabflow.highlights').setup()
  require('tabflow.autocmd').setup()
  require('tabflow.mouse').setup()

  -- Add current buffer at startup
  local state = require('tabflow.state')
  local bufnr = vim.api.nvim_get_current_buf()
  local current_tab = vim.api.nvim_get_current_tabpage()
  if require('tabflow.autocmd').is_normal_file_buffer(bufnr) then
    state.add_buffer(current_tab, bufnr)
    local s = state.get_tab_state(current_tab)
    s.current = bufnr
    state.save_tab_state(current_tab)
  end

  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require'tabflow.tabline'.render()"

  -- Define user commands
  local actions = require('tabflow.actions')
  vim.api.nvim_create_user_command('TabflowTabsMode', actions.enter_tabs_mode, {})
  vim.api.nvim_create_user_command('TabflowBuffersMode', actions.enter_buffers_mode, {})
  vim.api.nvim_create_user_command('TabflowToggleMode', actions.toggle_mode, {})
  vim.api.nvim_create_user_command('TabflowRenameTab', function(args)
    actions.rename_tab(vim.api.nvim_get_current_tabpage(), args.args)
  end, { nargs = 1 })
  vim.api.nvim_create_user_command('TabflowNewTab', function()
    vim.cmd('tabnew')
    actions.enter_buffers_mode()
  end, {})
  vim.api.nvim_create_user_command('TabflowCloseTab', function()
    actions.close_tab(vim.api.nvim_get_current_tabpage())
  end, {})
  vim.api.nvim_create_user_command('TabflowCloseBuffer', function()
    actions.close_buffer(vim.api.nvim_get_current_buf())
  end, {})
  vim.api.nvim_create_user_command('TabflowNextTab', actions.next_tab, {})
  vim.api.nvim_create_user_command('TabflowPrevTab', actions.prev_tab, {})
  vim.api.nvim_create_user_command('TabflowNextBuffer', actions.next_buffer, {})
  vim.api.nvim_create_user_command('TabflowPrevBuffer', actions.prev_buffer, {})
  vim.api.nvim_create_user_command('TabflowSetGitBranchName', function(args)
    require('tabflow.state').set_tab_name_to_git_branch()
  end, { nargs = 0 })
  vim.api.nvim_create_user_command('TabflowOpenWorktree', function(args)
    actions.select_worktree(args.args)
  end, {
    nargs = '?',
    complete = function()
      local worktrees = require('tabflow.state').get_git_worktrees()
      return vim.tbl_map(function(wt)
        return wt.branch
      end, worktrees)
    end,
  })
end

return M

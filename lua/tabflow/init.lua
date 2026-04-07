local M = {}

function M.setup(opts)
  opts = opts or {}
  opts.commands = opts.commands or {}

  local state = require('tabflow.state')
  if opts.icons then
    state.state.icons = vim.tbl_extend('force', state.state.icons, opts.icons)
  end

  require('tabflow.highlights').setup()
  local autocmd = require('tabflow.autocmd')
  autocmd.setup()
  require('tabflow.mouse').setup()

  -- Add current buffer at startup if it's a normal file
  local bufnr = vim.api.nvim_get_current_buf()
  if require('tabflow.util').is_normal_file_buffer(bufnr) then
    local current_tab = vim.api.nvim_get_current_tabpage()
    state.add_buffer(current_tab, bufnr)
    local s = state.get_tab_state(current_tab)
    s.current = bufnr
    state.save_tab_state(current_tab)
  end

  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require'tabflow.tabline'.render()"

  -- Register only configured commands
  local actions = require('tabflow.actions')
  local command_defs = {
    TabflowTabsMode = { fn = actions.enter_tabs_mode, opts = {} },
    TabflowBuffersMode = { fn = actions.enter_buffers_mode, opts = {} },
    TabflowToggleMode = { fn = actions.toggle_mode, opts = {} },
    TabflowNextTab = { fn = actions.next_tab, opts = {} },
    TabflowPrevTab = { fn = actions.prev_tab, opts = {} },
    TabflowNextBuffer = { fn = actions.next_buffer, opts = {} },
    TabflowPrevBuffer = { fn = actions.prev_buffer, opts = {} },
    TabflowRenameTab = {
      fn = function(args)
        actions.rename_tab(vim.api.nvim_get_current_tabpage(), args.args)
      end,
      opts = { nargs = 1 },
    },
    TabflowSetGitBranchName = {
      fn = function()
        require('tabflow.state').set_tab_name_to_git_branch()
      end,
      opts = { nargs = 0 },
    },
    TabflowNewTab = {
      fn = function()
        vim.cmd('tabnew')
        actions.enter_buffers_mode()
      end,
      opts = {},
    },
    TabflowCloseTab = {
      fn = function()
        actions.close_tab(vim.api.nvim_get_current_tabpage())
      end,
      opts = {},
    },
    TabflowCloseBuffer = {
      fn = function()
        actions.close_buffer(vim.api.nvim_get_current_buf())
      end,
      opts = {},
    },
    TabflowDeleteOtherBuffers = { fn = actions.delete_other_buffers, opts = {} },
    TabflowOpenWorktree = {
      fn = function(args)
        actions.select_worktree(args.args)
      end,
      opts = {
        nargs = '?',
        complete = function()
          local worktrees = require('tabflow.state').get_git_worktrees()
          return vim.tbl_map(function(wt)
            return wt.branch
          end, worktrees)
        end,
      },
    },
  }

  if type(opts.commands) == 'table' then
    for _, cmd_name in ipairs(opts.commands) do
      local cmd_def = command_defs[cmd_name]
      if cmd_def then
        vim.api.nvim_create_user_command(cmd_name, cmd_def.fn, cmd_def.opts)
      end
    end
  end
end

return M

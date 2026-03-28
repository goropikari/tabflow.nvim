local state = require('tabflow.state')

local M = {}

function M.toggle_mode()
  if state.state.mode == 'tabs' then
    state.state.mode = 'buffers'
  else
    state.state.mode = 'tabs'
  end
  vim.cmd('redrawtabline')
end

function M.enter_tabs_mode()
  state.state.mode = 'tabs'
  vim.cmd('redrawtabline')
end

function M.enter_buffers_mode()
  state.state.mode = 'buffers'
  vim.cmd('redrawtabline')
end

function M.switch_to_tab(tab_handle)
  vim.api.nvim_set_current_tabpage(tab_handle)
  local s = state.get_tab_state(tab_handle)
  if s.current and vim.api.nvim_buf_is_valid(s.current) then
    vim.api.nvim_set_current_buf(s.current)
  end
  state.state.mode = 'buffers'
  vim.cmd('redrawtabline')
end

function M.switch_to_buffer(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  local current_tab = vim.api.nvim_get_current_tabpage()
  local s = state.get_tab_state(current_tab)
  s.current = bufnr
  state.save_tab_state(current_tab)
  vim.cmd('redrawtabline')
end

function M.rename_tab(tab_handle, name)
  state.rename_tab(tab_handle, name)
  vim.cmd('redrawtabline')
end

function M.prompt_rename_tab(tab_handle)
  local current_name = state.get_tab_name(tab_handle)
  vim.ui.input({
    prompt = 'Rename Tab: ',
    default = current_name,
  }, function(input)
    if input and input ~= '' then
      M.rename_tab(tab_handle, input)
    end
  end)
end

function M.close_tab(tab_handle)
  state.remove_tab_state(tab_handle)
  vim.api.nvim_set_current_tabpage(tab_handle)
  vim.cmd('tabclose')
  vim.cmd('redrawtabline')
end

function M.close_buffer(bufnr)
  local current_tab = vim.api.nvim_get_current_tabpage()
  state.remove_buffer(current_tab, bufnr)

  -- If the buffer was active in the current window, switch to another one from the workspace
  if vim.api.nvim_get_current_buf() == bufnr then
    local s = state.get_tab_state(current_tab)
    if #s.buffers > 0 then
      -- Switch to the new "current" buffer in state, or the last one
      vim.api.nvim_set_current_buf(s.current or s.buffers[#s.buffers])
    else
      -- No more buffers in this workspace, maybe switch to an empty buffer?
      -- For now, let Neovim handle it or stay.
    end
  end

  if not M.is_buffer_in_any_tab(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = false })
  end
  vim.cmd('redrawtabline')
end

function M.is_buffer_in_any_tab(bufnr)
  for _, s in pairs(state.state.tabs) do
    for _, b in ipairs(s.buffers) do
      if b == bufnr then
        return true
      end
    end
  end
  return false
end

function M.reorder_tabs(source_tab, target_index)
  local tab_handles = vim.api.nvim_list_tabpages()
  local source_idx = 0
  for i, h in ipairs(tab_handles) do
    if h == source_tab then
      source_idx = i
      break
    end
  end

  if source_idx == 0 or source_idx == target_index then
    return
  end

  -- target_index is 1-based. tabmove 0 moves to first, tabmove 1 moves to after 1st.
  -- To move to position N (1-based), we use tabmove N-1.
  -- When moving right, the source tab is removed first, so we need to adjust the target index
  local current_tab = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_set_current_tabpage(source_tab)

  -- 右方向に移動する場合、source が抜ける分 target_index を 1 つ減らす
  local move_pos = target_index - 1
  if source_idx < target_index then
    move_pos = target_index - 2
  end

  vim.cmd('tabmove ' .. move_pos)

  -- Restore focus
  if vim.api.nvim_tabpage_is_valid(current_tab) then
    vim.api.nvim_set_current_tabpage(current_tab)
  end
  vim.cmd('redrawtabline')
end

function M.reorder_buffers(tab_handle, source_index, target_index)
  local s = state.get_tab_state(tab_handle)
  local bufnr = table.remove(s.buffers, source_index)
  table.insert(s.buffers, target_index, bufnr)
  state.save_tab_state(tab_handle)
  vim.cmd('redrawtabline')
end

function M.move_buffer_between_tabs(bufnr, source_tab, target_tab, target_index)
  state.remove_buffer(source_tab, bufnr)
  local s_target = state.get_tab_state(target_tab)
  if target_index then
    table.insert(s_target.buffers, target_index, bufnr)
  else
    table.insert(s_target.buffers, bufnr)
  end
  state.save_tab_state(target_tab)
  vim.cmd('redrawtabline')
end

function M.next_tab()
  local current = vim.api.nvim_get_current_tabpage()
  local tabs = vim.api.nvim_list_tabpages()
  for i, tab in ipairs(tabs) do
    if tab == current then
      local next_idx = i + 1
      if next_idx > #tabs then
        next_idx = 1
      end
      vim.api.nvim_set_current_tabpage(tabs[next_idx])
      break
    end
  end
  vim.cmd('redrawtabline')
end

function M.prev_tab()
  local current = vim.api.nvim_get_current_tabpage()
  local tabs = vim.api.nvim_list_tabpages()
  for i, tab in ipairs(tabs) do
    if tab == current then
      local prev_idx = i - 1
      if prev_idx < 1 then
        prev_idx = #tabs
      end
      vim.api.nvim_set_current_tabpage(tabs[prev_idx])
      break
    end
  end
  vim.cmd('redrawtabline')
end

function M.next_buffer()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local s = state.get_tab_state(current_tab)
  local current_buf = vim.api.nvim_get_current_buf()
  for i, bufnr in ipairs(s.buffers) do
    if bufnr == current_buf then
      local next_idx = i + 1
      if next_idx > #s.buffers then
        next_idx = 1
      end
      vim.api.nvim_set_current_buf(s.buffers[next_idx])
      s.current = s.buffers[next_idx]
      state.save_tab_state(current_tab)
      break
    end
  end
  vim.cmd('redrawtabline')
end

function M.prev_buffer()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local s = state.get_tab_state(current_tab)
  local current_buf = vim.api.nvim_get_current_buf()
  for i, bufnr in ipairs(s.buffers) do
    if bufnr == current_buf then
      local prev_idx = i - 1
      if prev_idx < 1 then
        prev_idx = #s.buffers
      end
      vim.api.nvim_set_current_buf(s.buffers[prev_idx])
      s.current = s.buffers[prev_idx]
      state.save_tab_state(current_tab)
      break
    end
  end
  vim.cmd('redrawtabline')
end

function M.select_worktree(branch_name)
  if branch_name and branch_name ~= '' then
    state.open_worktree_tab(branch_name)
    return
  end

  local worktrees = state.get_git_worktrees()
  if #worktrees == 0 then
    vim.notify('No git worktrees found', vim.log.levels.WARN)
    return
  end

  local branches = vim.tbl_map(function(wt)
    return wt.branch
  end, worktrees)

  vim.schedule(function()
    vim.ui.select(branches, {
      prompt = 'Select Git Worktree:',
      format_item = function(item)
        for _, wt in ipairs(worktrees) do
          if wt.branch == item then
            return string.format('%s (%s)', item, wt.path)
          end
        end
        return item
      end,
    }, function(choice)
      if choice then
        state.open_worktree_tab(choice)
      end
    end)
  end)
end

return M

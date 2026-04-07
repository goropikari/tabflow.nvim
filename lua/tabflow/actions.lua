local state = require('tabflow.state')

local M = {}

local function navigate_list(list, current_item, direction)
  if #list == 0 then
    return nil
  end
  for i, item in ipairs(list) do
    if item == current_item then
      local next_idx = i + direction
      if next_idx > #list then
        next_idx = 1
      elseif next_idx < 1 then
        next_idx = #list
      end
      return list[next_idx]
    end
  end
  return list[1]
end

function M.toggle_mode()
  state.state.mode = state.state.mode == 'tabs' and 'buffers' or 'tabs'
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

  if vim.api.nvim_get_current_buf() == bufnr then
    local s = state.get_tab_state(current_tab)
    if #s.buffers > 0 then
      vim.api.nvim_set_current_buf(s.current or s.buffers[#s.buffers])
    end
  end

  if not M.is_buffer_in_any_tab(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = false })
  end
  vim.cmd('redrawtabline')
end

function M.is_buffer_in_any_tab(bufnr)
  for _, s in pairs(state.state.tabs) do
    if vim.iter(s.buffers):find(function(b)
      return b == bufnr
    end) then
      return true
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

  local current_tab = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_set_current_tabpage(source_tab)

  local move_pos = target_index - 1
  if source_idx < target_index then
    move_pos = target_index - 2
  end

  vim.cmd('tabmove ' .. move_pos)

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
  local next_tab = navigate_list(tabs, current, 1)
  if next_tab then
    vim.api.nvim_set_current_tabpage(next_tab)
  end
  vim.cmd('redrawtabline')
end

function M.prev_tab()
  local current = vim.api.nvim_get_current_tabpage()
  local tabs = vim.api.nvim_list_tabpages()
  local prev_tab = navigate_list(tabs, current, -1)
  if prev_tab then
    vim.api.nvim_set_current_tabpage(prev_tab)
  end
  vim.cmd('redrawtabline')
end

function M.next_buffer()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local s = state.get_tab_state(current_tab)
  local current_buf = vim.api.nvim_get_current_buf()
  local next_buf = navigate_list(s.buffers, current_buf, 1)
  if next_buf then
    vim.api.nvim_set_current_buf(next_buf)
    s.current = next_buf
    state.save_tab_state(current_tab)
  end
  vim.cmd('redrawtabline')
end

function M.prev_buffer()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local s = state.get_tab_state(current_tab)
  local current_buf = vim.api.nvim_get_current_buf()
  local prev_buf = navigate_list(s.buffers, current_buf, -1)
  if prev_buf then
    vim.api.nvim_set_current_buf(prev_buf)
    s.current = prev_buf
    state.save_tab_state(current_tab)
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

function M.delete_other_buffers()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local current_buf = vim.api.nvim_get_current_buf()
  local s = state.get_tab_state(current_tab)

  local to_delete = vim.tbl_filter(function(b)
    return b ~= current_buf and vim.api.nvim_buf_is_valid(b)
  end, s.buffers)

  for _, bufnr in ipairs(to_delete) do
    state.remove_buffer(current_tab, bufnr)
    if not M.is_buffer_in_any_tab(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = false })
    end
  end

  s.buffers = { current_buf }
  s.current = current_buf
  state.save_tab_state(current_tab)
  vim.cmd('redrawtabline')
end

return M

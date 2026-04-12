local state = require('tabflow.state')

local M = {}
local move_tab_into_pinned_section

---@generic T
---@param list T[]
---@param current_item T
---@param direction integer
---@return T?
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

---@return nil
function M.toggle_mode()
  state.state.mode = state.state.mode == 'tabs' and 'buffers' or 'tabs'
  vim.cmd('redrawtabline')
end

---@return nil
function M.enter_tabs_mode()
  state.state.mode = 'tabs'
  vim.cmd('redrawtabline')
end

---@return nil
function M.enter_buffers_mode()
  state.state.mode = 'buffers'
  vim.cmd('redrawtabline')
end

---@param tab_handle integer
function M.switch_to_tab(tab_handle)
  vim.api.nvim_set_current_tabpage(tab_handle)
  local s = state.get_tab_state(tab_handle)
  if s.current and vim.api.nvim_buf_is_valid(s.current) then
    vim.api.nvim_set_current_buf(s.current)
  end
  state.state.mode = 'buffers'
  vim.cmd('redrawtabline')
end

---@param bufnr integer
function M.switch_to_buffer(bufnr)
  vim.api.nvim_set_current_buf(bufnr)
  local current_tab = vim.api.nvim_get_current_tabpage()
  local s = state.get_tab_state(current_tab)
  s.current = bufnr
  state.save_tab_state(current_tab)
  vim.cmd('redrawtabline')
end

---@param tab_handle integer
---@param name string
function M.rename_tab(tab_handle, name)
  state.rename_tab(tab_handle, name)
  vim.cmd('redrawtabline')
end

---@param tab_handle integer
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

---@param tab_handle integer
function M.toggle_tab_pinned(tab_handle)
  local pinned = not state.is_tab_pinned(tab_handle)
  state.set_tab_pinned(tab_handle, pinned)
  move_tab_into_pinned_section(tab_handle, pinned)
end

---@param tab_handle integer
function M.pin_tab(tab_handle)
  if not state.is_tab_pinned(tab_handle) then
    state.set_tab_pinned(tab_handle, true)
    move_tab_into_pinned_section(tab_handle, true)
  end
end

---@param tab_handle integer
function M.unpin_tab(tab_handle)
  if state.is_tab_pinned(tab_handle) then
    state.set_tab_pinned(tab_handle, false)
    move_tab_into_pinned_section(tab_handle, false)
  end
end

---@param tab_handle integer
function M.close_tab(tab_handle)
  if state.is_tab_pinned(tab_handle) then
    vim.notify('Pinned tabs cannot be closed. Unpin the tab first.', vim.log.levels.WARN)
    vim.cmd('redrawtabline')
    return
  end

  state.remove_tab_state(tab_handle)
  vim.api.nvim_set_current_tabpage(tab_handle)
  vim.cmd('tabclose')
  vim.cmd('redrawtabline')
end

---@param bufnr integer
---@return boolean
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

---@param bufnr integer
local function delete_if_unreferenced(bufnr)
  if not M.is_buffer_in_any_tab(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = false })
  end
end

---@param tab_handle integer
---@param pinned boolean
move_tab_into_pinned_section = function(tab_handle, pinned)
  local target_index
  if pinned then
    target_index = state.count_pinned_tabs()
  else
    target_index = state.count_pinned_tabs() + 1
  end
  M.reorder_tabs(tab_handle, target_index)
end

---@param bufnr integer
function M.close_buffer(bufnr)
  local current_tab = vim.api.nvim_get_current_tabpage()
  state.remove_buffer(current_tab, bufnr)

  if vim.api.nvim_get_current_buf() == bufnr then
    local s = state.get_tab_state(current_tab)
    if #s.buffers > 0 then
      vim.api.nvim_set_current_buf(s.current or s.buffers[#s.buffers])
    end
  end

  delete_if_unreferenced(bufnr)
  vim.cmd('redrawtabline')
end

---@param source_tab integer
---@param target_index integer
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

  local pinned_count = state.count_pinned_tabs()
  local source_is_pinned = state.is_tab_pinned(source_tab)

  if source_is_pinned then
    target_index = math.max(1, math.min(target_index, pinned_count))
  else
    target_index = math.max(pinned_count + 1, math.min(target_index, #tab_handles))
  end

  if source_idx == target_index then
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

---@param tab_handle integer
---@param source_index integer
---@param target_index integer
function M.reorder_buffers(tab_handle, source_index, target_index)
  local s = state.get_tab_state(tab_handle)
  local bufnr = table.remove(s.buffers, source_index)
  table.insert(s.buffers, target_index, bufnr)
  state.save_tab_state(tab_handle)
  vim.cmd('redrawtabline')
end

---@param bufnr integer
---@param source_tab integer
---@param target_tab integer
---@param target_index? integer
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

---@param kind 'tab'|'buffer'
---@param direction integer
function M.navigate(kind, direction)
  if kind == 'tab' then
    local current = vim.api.nvim_get_current_tabpage()
    local tabs = vim.api.nvim_list_tabpages()
    local target = navigate_list(tabs, current, direction)
    if target then
      vim.api.nvim_set_current_tabpage(target)
    end
  else
    local current_tab = vim.api.nvim_get_current_tabpage()
    local s = state.get_tab_state(current_tab)
    local current_buf = vim.api.nvim_get_current_buf()
    local target = navigate_list(s.buffers, current_buf, direction)
    if target then
      vim.api.nvim_set_current_buf(target)
      s.current = target
      state.save_tab_state(current_tab)
    end
  end
  vim.cmd('redrawtabline')
end

---@return nil
function M.next_tab()
  M.navigate('tab', 1)
end

---@return nil
function M.prev_tab()
  M.navigate('tab', -1)
end

---@return nil
function M.next_buffer()
  M.navigate('buffer', 1)
end

---@return nil
function M.prev_buffer()
  M.navigate('buffer', -1)
end

---@param branch_name? string
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
    delete_if_unreferenced(bufnr)
  end

  s.buffers = { current_buf }
  s.current = current_buf
  state.save_tab_state(current_tab)
  vim.cmd('redrawtabline')
end

return M

local M = {}

M.state = {
  mode = 'tabs', -- "tabs" or "buffers"

  icons = {
    color = true,
  },

  markers = {
    modified = '●',
    unmodified = '',
    pinned = '[P]',
  },

  diagnostics = {
    enabled = true,
    markers = {
      error = 'E',
      warn = 'W',
      info = 'I',
      hint = 'H',
    },
  },

  drag = {
    active = false,
    kind = nil, -- "tab" or "buffer"
    source_id = nil, -- tab handle or bufnr
    source_tab = nil, -- only relevant for buffer drag
    source_index = nil,
    start_mouse = nil, -- { row, col }
    hover_target = nil, -- current drop target
    window = nil, -- Ghost window for drag feedback (NVIM 0.11+)
    buffer = nil, -- Buffer for ghost window
  },

  layout = {
    items = {}, -- rendered hit-test items
    revision = 0,
  },

  tabs = {}, -- [tab_handle] = { name = string, buffers = { bufnr, ... }, current = bufnr }
}

function M.get_tab_state(tab_handle)
  tab_handle = tab_handle or vim.api.nvim_get_current_tabpage()
  if not M.state.tabs[tab_handle] then
    M.ensure_tab(tab_handle)
  end
  return M.state.tabs[tab_handle]
end

local function get_tab_var(tab_handle, name, default)
  local ok, val = pcall(vim.api.nvim_tabpage_get_var, tab_handle, name)
  return ok and val or default
end

local function get_tab_title(tab_handle)
  return get_tab_var(tab_handle, 'tabflow_name', get_tab_var(tab_handle, 'title'))
end

function M.ensure_tab(tab_handle)
  if not M.state.tabs[tab_handle] then
    if not vim.api.nvim_tabpage_is_valid(tab_handle) then
      return
    end

    local name = get_tab_title(tab_handle)
    local buffers = get_tab_var(tab_handle, 'tabflow_buffers', {})
    local current = get_tab_var(tab_handle, 'tabflow_current')
    local pinned = get_tab_var(tab_handle, 'tabflow_pinned', false)

    -- Use git branch name as default if no name set
    if not name or name:match('^Tab %d+$') then
      local branch = require('tabflow.util').git_branch()
      if branch then
        name = branch
      end
    end

    M.state.tabs[tab_handle] = {
      name = name or ('Tab ' .. vim.api.nvim_tabpage_get_number(tab_handle)),
      buffers = buffers,
      current = current,
      pinned = pinned,
    }
    M.save_tab_state(tab_handle)
  end
end

function M.add_buffer(tab_handle, bufnr)
  local s = M.get_tab_state(tab_handle)
  if not s then
    return
  end

  if vim.iter(s.buffers):find(function(b)
    return b == bufnr
  end) then
    return
  end

  table.insert(s.buffers, bufnr)
  M.save_tab_state(tab_handle)
end

function M.remove_buffer(tab_handle, bufnr)
  local s = M.get_tab_state(tab_handle)
  if not s then
    return
  end

  local removed = false
  for i, b in ipairs(s.buffers) do
    if b == bufnr then
      table.remove(s.buffers, i)
      removed = true
      break
    end
  end

  if not removed then
    return
  end

  -- Update current buffer if it was the one removed
  if s.current == bufnr then
    s.current = s.buffers[#s.buffers] or nil
  end
  M.save_tab_state(tab_handle)
end

function M.remove_buffer_everywhere(bufnr)
  for tab_handle, _ in pairs(M.state.tabs) do
    M.remove_buffer(tab_handle, bufnr)
  end
end

function M.remove_tab_state(tab_handle)
  if vim.api.nvim_tabpage_is_valid(tab_handle) then
    pcall(vim.api.nvim_tabpage_del_var, tab_handle, 'tabflow_name')
    pcall(vim.api.nvim_tabpage_del_var, tab_handle, 'tabflow_buffers')
    pcall(vim.api.nvim_tabpage_del_var, tab_handle, 'tabflow_current')
    pcall(vim.api.nvim_tabpage_del_var, tab_handle, 'tabflow_pinned')
  end
  M.state.tabs[tab_handle] = nil
end

local function get_fallback_tab_name(tab_handle)
  if vim.api.nvim_tabpage_is_valid(tab_handle) then
    return 'Tab ' .. vim.api.nvim_tabpage_get_number(tab_handle)
  end
  return 'Tab ?'
end

function M.get_tab_name(tab_handle)
  local s = M.get_tab_state(tab_handle)
  if not s then
    return get_fallback_tab_name(tab_handle)
  end

  if s.name and not s.name:match('^Tab %d+$') then
    return s.name
  end

  if s.current and vim.api.nvim_buf_is_valid(s.current) then
    local bufname = vim.api.nvim_buf_get_name(s.current)
    if bufname ~= '' then
      return vim.fn.fnamemodify(bufname, ':t')
    end
  end

  return get_fallback_tab_name(tab_handle)
end

function M.tab_has_modified_buffers(tab_handle)
  local s = M.get_tab_state(tab_handle)
  if not s then
    return false
  end

  for _, bufnr in ipairs(s.buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_option_value('modified', { buf = bufnr }) then
      return true
    end
  end

  return false
end

function M.is_tab_pinned(tab_handle)
  local s = M.get_tab_state(tab_handle)
  return s and s.pinned or false
end

function M.set_tab_pinned(tab_handle, pinned)
  local s = M.get_tab_state(tab_handle)
  if not s then
    return
  end

  s.pinned = pinned and true or false
  M.save_tab_state(tab_handle)
end

function M.count_pinned_tabs()
  local count = 0
  for _, tab_handle in ipairs(vim.api.nvim_list_tabpages()) do
    if M.is_tab_pinned(tab_handle) then
      count = count + 1
    end
  end
  return count
end

local function count_diagnostics_for_buffer(bufnr)
  local counts = {
    error = 0,
    warn = 0,
    info = 0,
    hint = 0,
  }

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return counts
  end

  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      counts.error = counts.error + 1
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      counts.warn = counts.warn + 1
    elseif diagnostic.severity == vim.diagnostic.severity.INFO then
      counts.info = counts.info + 1
    elseif diagnostic.severity == vim.diagnostic.severity.HINT then
      counts.hint = counts.hint + 1
    end
  end

  return counts
end

local function merge_diagnostic_counts(base, extra)
  base.error = base.error + extra.error
  base.warn = base.warn + extra.warn
  base.info = base.info + extra.info
  base.hint = base.hint + extra.hint
  return base
end

function M.get_buffer_diagnostic_counts(bufnr)
  return count_diagnostics_for_buffer(bufnr)
end

function M.get_tab_diagnostic_counts(tab_handle)
  local s = M.get_tab_state(tab_handle)
  local counts = {
    error = 0,
    warn = 0,
    info = 0,
    hint = 0,
  }

  if not s then
    return counts
  end

  for _, bufnr in ipairs(s.buffers) do
    merge_diagnostic_counts(counts, count_diagnostics_for_buffer(bufnr))
  end

  return counts
end

function M.rename_tab(tab_handle, name)
  local s = M.get_tab_state(tab_handle)
  if s then
    s.name = name
    M.save_tab_state(tab_handle)
  end
end

function M.set_tab_name_to_git_branch(tab_handle)
  tab_handle = tab_handle or vim.api.nvim_get_current_tabpage()
  local branch = require('tabflow.util').git_branch()
  if not branch then
    vim.notify('Not in a git repository or no branch found', vim.log.levels.WARN)
    return
  end

  M.rename_tab(tab_handle, branch)
  vim.cmd('redrawtabline')
end

function M.get_git_worktrees()
  local util = require('tabflow.util')
  local root = util.git_root()
  if not root then
    return {}
  end

  local output = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' worktree list 2>/dev/null')
  local worktrees = {}

  for line in output:gmatch('[^\n]+') do
    local path = line:match('^(%S+)')
    local branch = line:match('%[([^%]]+)%]')
    if path and branch then
      table.insert(worktrees, {
        path = path,
        branch = branch,
      })
    end
  end

  return worktrees
end

function M.open_worktree_tab(branch_name)
  local worktrees = M.get_git_worktrees()
  local target = nil

  for _, wt in ipairs(worktrees) do
    if wt.branch == branch_name then
      target = wt
      break
    end
  end

  if not target then
    vim.notify('No worktree found for branch: ' .. branch_name, vim.log.levels.ERROR)
    return
  end

  vim.cmd('tabnew')
  vim.cmd('tcd ' .. target.path)

  local tab_handle = vim.api.nvim_get_current_tabpage()
  M.rename_tab(tab_handle, branch_name)

  vim.notify('Switched to worktree: ' .. target.path .. ' (' .. branch_name .. ')')
end

local function save_tab_state_to_vars(tab_handle, s)
  if not vim.api.nvim_tabpage_is_valid(tab_handle) then
    return
  end
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'tabflow_name', s.name)
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'title', s.name)
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'tabflow_buffers', s.buffers)
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'tabflow_current', s.current)
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'tabflow_pinned', s.pinned)
end

function M.save_tab_state(tab_handle)
  local s = M.state.tabs[tab_handle]
  if not s then
    return
  end

  if not vim.api.nvim_tabpage_is_valid(tab_handle) then
    M.state.tabs[tab_handle] = nil
    return
  end

  save_tab_state_to_vars(tab_handle, s)
  M.sync_to_global()
end

function M.sync_to_global()
  local data = {
    names = {},
    buffers = {},
    currents = {},
    pinned = {},
  }
  local tabs = vim.api.nvim_list_tabpages()
  for i, tab_handle in ipairs(tabs) do
    local s = M.state.tabs[tab_handle]
    if s then
      data.names[i] = s.name
      data.buffers[i] = s.buffers
      data.currents[i] = s.current
      data.pinned[i] = s.pinned
    else
      data.names[i] = get_tab_title(tab_handle)
    end
  end
  vim.g.TabflowStateJson = vim.json.encode(data)
end

function M.restore_from_global()
  local json = vim.g.TabflowStateJson
  if not json or json == '' then
    return
  end

  local ok, data = pcall(vim.json.decode, json)
  if not ok or not data then
    return
  end

  local names = data.names or {}
  local buffers = data.buffers or {}
  local currents = data.currents or {}
  local pinned = data.pinned or {}

  local tabs = vim.api.nvim_list_tabpages()
  for i = 1, #tabs do
    local name = names[i] or names[tostring(i)]
    local tab_handle = tabs[i]
    M.ensure_tab(tab_handle)
    local s = M.state.tabs[tab_handle]
    if s then
      if name and name ~= '' then
        s.name = name
      end
      local bufs = buffers[i] or buffers[tostring(i)]
      if bufs then
        s.buffers = bufs
      end
      local cur = currents[i] or currents[tostring(i)]
      if cur then
        s.current = cur
      end
      local pin = pinned[i]
      if pin == nil then
        pin = pinned[tostring(i)]
      end
      if pin ~= nil then
        s.pinned = pin and true or false
      end
      save_tab_state_to_vars(tab_handle, s)
    end
  end
end

function M.get_mode()
  return M.state.mode
end

return M

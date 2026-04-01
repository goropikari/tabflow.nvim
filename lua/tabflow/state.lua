local M = {}

M.state = {
  mode = 'buffers', -- "tabs" or "buffers"

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

function M.ensure_tab(tab_handle)
  if not M.state.tabs[tab_handle] then
    if not vim.api.nvim_tabpage_is_valid(tab_handle) then
      return
    end

    -- title (一般的に使われる) または tabflow_name から読み込み
    local ok_name, name = pcall(vim.api.nvim_tabpage_get_var, tab_handle, 'title')
    if not ok_name then
      ok_name, name = pcall(vim.api.nvim_tabpage_get_var, tab_handle, 'tabflow_name')
    end
    if not ok_name then
      name = nil
    end

    local ok_bufs, buffers = pcall(vim.api.nvim_tabpage_get_var, tab_handle, 'tabflow_buffers')
    if not ok_bufs then
      buffers = {}
    end

    local ok_cur, current = pcall(vim.api.nvim_tabpage_get_var, tab_handle, 'tabflow_current')
    if not ok_cur then
      current = nil
    end

    -- 名前が設定されていない場合、git branch 名をデフォルトにする
    if not name or name:match('^Tab %d+$') then
      local root = vim.fn.system('git -C ' .. vim.fn.shellescape(vim.fn.getcwd()) .. ' rev-parse --show-toplevel 2>/dev/null')
      root = root:gsub('%s+$', '')
      if root ~= '' then
        local branch = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' symbolic-ref --short HEAD 2>/dev/null')
        branch = branch:gsub('%s+$', '')
        if branch == '' or branch == 'HEAD' then
          local hash = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' rev-parse --short HEAD 2>/dev/null')
          hash = hash:gsub('%s+$', '')
          branch = hash ~= '' and hash or nil
        end
        if branch and branch ~= '' then
          name = branch
        end
      end
    end

    M.state.tabs[tab_handle] = {
      name = name or ('Tab ' .. vim.api.nvim_tabpage_get_number(tab_handle)),
      buffers = buffers,
      current = current,
    }
  end
end

function M.add_buffer(tab_handle, bufnr)
  local s = M.get_tab_state(tab_handle)
  if not s then
    return
  end

  -- Use vim.iter for 0.11 style
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

  for i, b in ipairs(s.buffers) do
    if b == bufnr then
      table.remove(s.buffers, i)
      break
    end
  end
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
  M.state.tabs[tab_handle] = nil
  if vim.api.nvim_tabpage_is_valid(tab_handle) then
    pcall(vim.api.nvim_tabpage_del_var, tab_handle, 'tabflow_name')
    pcall(vim.api.nvim_tabpage_del_var, tab_handle, 'tabflow_buffers')
    pcall(vim.api.nvim_tabpage_del_var, tab_handle, 'tabflow_current')
  end
end

function M.get_tab_name(tab_handle)
  local s = M.get_tab_state(tab_handle)
  if not s then
    if vim.api.nvim_tabpage_is_valid(tab_handle) then
      return 'Tab ' .. vim.api.nvim_tabpage_get_number(tab_handle)
    end
    return 'Tab ?'
  end

  -- 1. 明示的に設定された名前がある場合（Tab N というデフォルト形式以外）
  if s.name and not s.name:match('^Tab %d+$') then
    return s.name
  end

  -- 2. タブ内で最後にアクティブだったバッファ名を使用
  if s.current and vim.api.nvim_buf_is_valid(s.current) then
    local bufname = vim.api.nvim_buf_get_name(s.current)
    if bufname ~= '' then
      return vim.fn.fnamemodify(bufname, ':t')
    end
  end

  -- 3. 代替として現在のタブ番号
  if vim.api.nvim_tabpage_is_valid(tab_handle) then
    return 'Tab ' .. vim.api.nvim_tabpage_get_number(tab_handle)
  end
  return 'Tab ?'
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
  if not vim.api.nvim_tabpage_is_valid(tab_handle) then
    return
  end

  local root = vim.fn.system('git -C ' .. vim.fn.shellescape(vim.fn.getcwd()) .. ' rev-parse --show-toplevel 2>/dev/null')
  root = root:gsub('%s+$', '')
  if root == '' then
    vim.notify('Not in a git repository', vim.log.levels.WARN)
    return
  end

  -- ブランチ名を取得（シンボリックリンクを追従）
  local branch = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' symbolic-ref --short HEAD 2>/dev/null')
  branch = branch:gsub('%s+$', '')

  -- シンボリック参照が失敗した場合（detached HEAD など）、short hash を使用
  if branch == '' or branch == 'HEAD' then
    local hash = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' rev-parse --short HEAD 2>/dev/null')
    hash = hash:gsub('%s+$', '')
    branch = hash ~= '' and hash or 'unknown'
  end

  M.rename_tab(tab_handle, branch)
  vim.cmd('redrawtabline')
end

-- git worktree の一覧を取得
function M.get_git_worktrees()
  local root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('%s+$', '')
  if root == '' then
    return {}
  end

  local output = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' worktree list 2>/dev/null')
  local worktrees = {}

  for line in output:gmatch('[^\n]+') do
    -- 形式：/path/to/dir <commit> [branch]
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

-- 指定したブランチの worktree に移動して新規タブ作成
function M.open_worktree_tab(branch_name)
  local worktrees = M.get_git_worktrees()
  local target = nil

  -- 既存の worktree を探す
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

  -- 現在のタブを保存
  local original_tab = vim.api.nvim_get_current_tabpage()

  -- 新規タブを作成
  vim.cmd('tabnew')

  -- 新規タブのディレクトリを worktree に移動 (タブローカル)
  vim.cmd('tcd ' .. target.path)

  -- タブ名をブランチ名に設定
  local tab_handle = vim.api.nvim_get_current_tabpage()
  M.rename_tab(tab_handle, branch_name)

  vim.notify('Switched to worktree: ' .. target.path .. ' (' .. branch_name .. ')')
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

  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'tabflow_name', s.name)
  -- title 変数 (t:title) も更新して他プラグインとも同期
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'title', s.name)
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'tabflow_buffers', s.buffers)
  pcall(vim.api.nvim_tabpage_set_var, tab_handle, 'tabflow_current', s.current)
end

return M

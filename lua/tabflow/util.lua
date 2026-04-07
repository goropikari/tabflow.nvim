local M = {}

function M.get_unique_labels(bufnrs)
  local labels = {}
  local full_paths = {}
  local name_counts = {}

  for _, bufnr in ipairs(bufnrs) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local path = vim.api.nvim_buf_get_name(bufnr)
      full_paths[bufnr] = path
      if path ~= '' then
        local filename = vim.fn.fnamemodify(path, ':t')
        name_counts[filename] = (name_counts[filename] or 0) + 1
      end
    end
  end

  for bufnr, path in pairs(full_paths) do
    if path == '' then
      labels[bufnr] = '[No Name]'
    else
      local filename = vim.fn.fnamemodify(path, ':t')
      if name_counts[filename] > 1 then
        labels[bufnr] = vim.fn.fnamemodify(path, ':p:h:t') .. '/' .. filename
      else
        labels[bufnr] = filename
      end
    end
  end

  return labels
end

function M.git_root(path)
  path = path or vim.fn.getcwd()
  local root = vim.fn.system('git -C ' .. vim.fn.shellescape(path) .. ' rev-parse --show-toplevel 2>/dev/null')
  root = root:gsub('%s+$', '')
  return root ~= '' and root or nil
end

function M.git_branch(root)
  root = root or M.git_root()
  if not root then
    return nil
  end

  local branch = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' symbolic-ref --short HEAD 2>/dev/null')
  branch = branch:gsub('%s+$', '')

  if branch == '' or branch == 'HEAD' then
    local hash = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' rev-parse --short HEAD 2>/dev/null')
    hash = hash:gsub('%s+$', '')
    branch = hash ~= '' and hash or nil
  end

  return branch ~= '' and branch or nil
end

function M.is_normal_file_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local buflisted = vim.api.nvim_get_option_value('buflisted', { buf = bufnr })
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
  return buflisted and buftype == ''
end

return M

local M = {}

function M.get_unique_labels(bufnrs)
  local labels = {}
  local full_paths = {}
  for _, bufnr in ipairs(bufnrs) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      full_paths[bufnr] = vim.api.nvim_buf_get_name(bufnr)
    end
  end

  -- Simplified unique name logic
  for bufnr, path in pairs(full_paths) do
    if path == '' then
      labels[bufnr] = '[No Name]'
    else
      local filename = vim.fn.fnamemodify(path, ':t')
      local is_duplicate = false
      for other_bufnr, other_path in pairs(full_paths) do
        if bufnr ~= other_bufnr and vim.fn.fnamemodify(other_path, ':t') == filename then
          is_duplicate = true
          break
        end
      end

      if is_duplicate then
        labels[bufnr] = vim.fn.fnamemodify(path, ':p:h:t') .. '/' .. filename
      else
        labels[bufnr] = filename
      end
    end
  end

  return labels
end

return M

local state = require('tabflow.state')

local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup('tabflow', { clear = true })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      if require('tabflow.util').is_normal_file_buffer(bufnr) then
        local current_tab = vim.api.nvim_get_current_tabpage()
        state.add_buffer(current_tab, bufnr)

        local s = state.get_tab_state(current_tab)
        if s then
          s.current = bufnr
          state.save_tab_state(current_tab)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufDelete' }, {
    group = group,
    callback = function(ev)
      state.remove_buffer_everywhere(ev.buf)
      vim.cmd('redrawtabline')
    end,
  })

  vim.api.nvim_create_autocmd('TabClosed', {
    group = group,
    callback = function(ev)
      local tab_handle = tonumber(ev.file)
      if tab_handle then
        state.remove_tab_state(tab_handle)
      end
      vim.cmd('redrawtabline')
    end,
  })

  vim.api.nvim_create_autocmd('TabEnter', {
    group = group,
    callback = function()
      local current_tab = vim.api.nvim_get_current_tabpage()
      state.ensure_tab(current_tab)
      vim.cmd('redrawtabline')
    end,
  })

  vim.api.nvim_create_autocmd('SessionLoadPost', {
    group = group,
    callback = function()
      state.state.tabs = {}
      state.restore_from_global()
      vim.cmd('redrawtabline')
    end,
  })

  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = group,
    callback = function()
      vim.cmd('redrawtabline')
    end,
  })
end

return M

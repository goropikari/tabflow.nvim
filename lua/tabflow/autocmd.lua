local state = require('tabflow.state')

local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup('tabflow', { clear = true })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      if M.is_normal_file_buffer(bufnr) then
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

  -- Clean up buffer references in tab states when buffers are deleted/wiped out
  local function cleanup_buffer_in_all_tabs(bufnr)
    for tab_handle, s in pairs(state.state.tabs) do
      if s.buffers and type(s.buffers) == 'table' then
        for i, b in ipairs(s.buffers) do
          if b == bufnr then
            table.remove(s.buffers, i)
            break
          end
        end
        -- Update current buffer if it was deleted
        if s.current == bufnr then
          s.current = s.buffers[#s.buffers] or nil
          state.save_tab_state(tab_handle)
        end
      end
    end
    vim.cmd('redrawtabline')
  end

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    callback = function(ev)
      cleanup_buffer_in_all_tabs(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(ev)
      cleanup_buffer_in_all_tabs(ev.buf)
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
      -- セッション読み込み後に内部状態をクリアして、グローバル変数から復元する
      state.state.tabs = {}
      state.restore_from_global()
      vim.cmd('redrawtabline')
    end,
  })
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

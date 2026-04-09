local script_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local root_dir = vim.fn.fnamemodify(script_dir .. '/..', ':p')

vim.opt.runtimepath:prepend(root_dir)

require('tabflow').setup({
  commands = {
    'TabflowTabsMode',
    'TabflowBuffersMode',
    'TabflowToggleMode',
    'TabflowNextTab',
    'TabflowPrevTab',
    'TabflowNextBuffer',
    'TabflowPrevBuffer',
    'TabflowRenameTab',
    'TabflowTogglePinTab',
    'TabflowPinTab',
    'TabflowUnpinTab',
    'TabflowSetGitBranchName',
    'TabflowNewTab',
    'TabflowCloseTab',
    'TabflowCloseBuffer',
    'TabflowDeleteOtherBuffers',
    'TabflowOpenWorktree',
  },
})

local diagnostic_ns = vim.api.nvim_create_namespace('tabflow-dev')

local function ensure_demo_buffer(bufnr, name)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if vim.api.nvim_buf_get_name(bufnr) == '' then
    vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. '-' .. name .. '.lua')
  end

  if vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)[1] == '' then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'local demo = true',
      'return demo',
    })
  end
end

vim.api.nvim_create_user_command('TabflowDevDiagnosticsSample', function()
  local bufnr = vim.api.nvim_get_current_buf()
  ensure_demo_buffer(bufnr, 'diagnostics')

  vim.diagnostic.set(diagnostic_ns, bufnr, {
    { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = 'sample error' },
    { lnum = 0, col = 6, severity = vim.diagnostic.severity.WARN, message = 'sample warning' },
    { lnum = 1, col = 0, severity = vim.diagnostic.severity.INFO, message = 'sample info' },
    { lnum = 1, col = 7, severity = vim.diagnostic.severity.HINT, message = 'sample hint' },
  })
end, {})

vim.api.nvim_create_user_command('TabflowDevDiagnosticsClear', function()
  vim.diagnostic.reset(diagnostic_ns, vim.api.nvim_get_current_buf())
end, {})

vim.api.nvim_create_user_command('TabflowDevDemo', function()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local first_buf = vim.api.nvim_get_current_buf()
  ensure_demo_buffer(first_buf, 'tab1')
  require('tabflow.state').add_buffer(current_tab, first_buf)
  require('tabflow.actions').rename_tab(current_tab, 'Demo A')
  vim.diagnostic.set(diagnostic_ns, first_buf, {
    { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = 'sample error' },
    { lnum = 1, col = 0, severity = vim.diagnostic.severity.WARN, message = 'sample warning' },
  })

  vim.cmd('tabnew')
  local second_tab = vim.api.nvim_get_current_tabpage()
  local second_buf = vim.api.nvim_get_current_buf()
  ensure_demo_buffer(second_buf, 'tab2')
  require('tabflow.state').add_buffer(second_tab, second_buf)
  require('tabflow.actions').rename_tab(second_tab, 'Demo B')
  require('tabflow.actions').pin_tab(second_tab)
  vim.diagnostic.set(diagnostic_ns, second_buf, {
    { lnum = 0, col = 0, severity = vim.diagnostic.severity.HINT, message = 'sample hint' },
    { lnum = 1, col = 0, severity = vim.diagnostic.severity.INFO, message = 'sample info' },
  })

  vim.api.nvim_set_current_tabpage(current_tab)
  vim.cmd('TabflowTabsMode')
end, {})

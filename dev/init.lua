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

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ','
vim.g.maplocalleader = ','

local function dir_path_or(path, default)
  local expanded = vim.fn.expand(path)
  local stat = vim.uv.fs_stat(expanded)

  if stat and stat.type == 'directory' then
    return expanded
  end

  return default
end

-- Setup lazy.nvim
require('lazy').setup({
  spec = {
    {
      {
        dir = dir_path_or('/workspaces/tabflow-nvim', '/workspaces/tabflow.nvim'),
        opts = {},
      },
    },
  },
  install = { colorscheme = { 'habamax' } },
  checker = { enabled = true },
})

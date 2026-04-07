local M = {}

function M.setup()
  -- Default highlights linked to standard tabline groups
  vim.api.nvim_set_hl(0, 'IdeTablineActive', { link = 'TabLineSel' })
  vim.api.nvim_set_hl(0, 'IdeTablineInactive', { link = 'TabLine' })
  vim.api.nvim_set_hl(0, 'IdeTablineFill', { link = 'TabLineFill' })
  vim.api.nvim_set_hl(0, 'IdeTablineSeparator', { link = 'TabLine' })
  vim.api.nvim_set_hl(0, 'IdeTablineModified', { fg = '#e0af68', bold = true }) -- Example color
  vim.api.nvim_set_hl(0, 'IdeTablineHover', { link = 'Visual' })
end

return M

local util = require('tabflow.util')

describe('tabflow.util', function()
  it('returns [No Name] for buffers with no path', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    local labels = util.get_unique_labels({ bufnr })
    assert.are.equal('[No Name]', labels[bufnr])
  end)

  it('returns filename for buffers with path', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/home/user/project/file.lua')
    local labels = util.get_unique_labels({ bufnr })
    assert.are.equal('file.lua', labels[bufnr])
  end)

  it('disambiguates duplicate filenames with parent directory', function()
    local bufnr1 = vim.api.nvim_create_buf(false, true)
    local bufnr2 = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr1, '/home/user/project/a/file.lua')
    vim.api.nvim_buf_set_name(bufnr2, '/home/user/project/b/file.lua')

    local labels = util.get_unique_labels({ bufnr1, bufnr2 })

    assert.are.equal('a/file.lua', labels[bufnr1])
    assert.are.equal('b/file.lua', labels[bufnr2])
  end)
end)

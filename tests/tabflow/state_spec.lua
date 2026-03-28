local state = require('tabflow.state')

describe('tabflow.state', function()
  before_each(function()
    -- Clear state before each test
    state.state.tabs = {}
    -- Clear tab-local variables for the current tab
    local tab = vim.api.nvim_get_current_tabpage()
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_name')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_buffers')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_current')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'title')
  end)

  it('can add a buffer to a tab', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local bufnr = vim.api.nvim_create_buf(false, true)

    state.add_buffer(tab, bufnr)

    local s = state.get_tab_state(tab)
    assert.is_not_nil(s)
    assert.are.same({ bufnr }, s.buffers)
  end)

  it('can remove a buffer from a tab', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local bufnr1 = vim.api.nvim_create_buf(false, true)
    local bufnr2 = vim.api.nvim_create_buf(false, true)

    state.add_buffer(tab, bufnr1)
    state.add_buffer(tab, bufnr2)

    state.remove_buffer(tab, bufnr1)

    local s = state.get_tab_state(tab)
    assert.are.same({ bufnr2 }, s.buffers)
  end)

  it('prevents duplicate buffers in a tab', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local bufnr = vim.api.nvim_create_buf(false, true)

    state.add_buffer(tab, bufnr)
    state.add_buffer(tab, bufnr)

    local s = state.get_tab_state(tab)
    assert.are.same({ bufnr }, s.buffers)
  end)

  it('can rename a tab', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local name = 'My Custom Tab'

    state.rename_tab(tab, name)

    local s = state.get_tab_state(tab)
    assert.are.equal(name, s.name)
  end)
end)

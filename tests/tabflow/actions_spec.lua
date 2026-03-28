local actions = require('tabflow.actions')
local state = require('tabflow.state')

describe('tabflow.actions', function()
  before_each(function()
    state.state.mode = 'buffers'
    state.state.tabs = {}
    -- Reset to 1 tab
    while #vim.api.nvim_list_tabpages() > 1 do
      vim.cmd('tabclose')
    end
    local tab = vim.api.nvim_get_current_tabpage()
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_name')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_buffers')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_current')
  end)

  it('can toggle between tabs and buffers mode', function()
    assert.are.equal('buffers', state.state.mode)
    actions.toggle_mode()
    assert.are.equal('tabs', state.state.mode)
    actions.toggle_mode()
    assert.are.equal('buffers', state.state.mode)
  end)

  it('can navigate between tabs', function()
    vim.cmd('tabnew')
    vim.cmd('tabnew')
    local tabs = vim.api.nvim_list_tabpages()
    assert.are.equal(3, #tabs)

    vim.api.nvim_set_current_tabpage(tabs[1])
    actions.next_tab()
    assert.are.equal(tabs[2], vim.api.nvim_get_current_tabpage())

    actions.next_tab()
    assert.are.equal(tabs[3], vim.api.nvim_get_current_tabpage())

    actions.next_tab()
    assert.are.equal(tabs[1], vim.api.nvim_get_current_tabpage())

    actions.prev_tab()
    assert.are.equal(tabs[3], vim.api.nvim_get_current_tabpage())
  end)

  it('can navigate between buffers in current workspace', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local b1 = vim.api.nvim_create_buf(false, true)
    local b2 = vim.api.nvim_create_buf(false, true)
    local b3 = vim.api.nvim_create_buf(false, true)

    state.add_buffer(tab, b1)
    state.add_buffer(tab, b2)
    state.add_buffer(tab, b3)

    vim.api.nvim_set_current_buf(b1)
    actions.next_buffer()
    assert.are.equal(b2, vim.api.nvim_get_current_buf())

    actions.next_buffer()
    assert.are.equal(b3, vim.api.nvim_get_current_buf())

    actions.next_buffer()
    assert.are.equal(b1, vim.api.nvim_get_current_buf())

    actions.prev_buffer()
    assert.are.equal(b3, vim.api.nvim_get_current_buf())
  end)

  it('can close a buffer and switch to another in the workspace', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local b1 = vim.api.nvim_create_buf(false, true)
    local b2 = vim.api.nvim_create_buf(false, true)

    state.add_buffer(tab, b1)
    state.add_buffer(tab, b2)

    vim.api.nvim_set_current_buf(b1)
    actions.close_buffer(b1)

    assert.are.equal(b2, vim.api.nvim_get_current_buf())
    local s = state.get_tab_state(tab)
    assert.are.same({ b2 }, s.buffers)
  end)

  it('can rename a tab', function()
    local tab = vim.api.nvim_get_current_tabpage()
    actions.rename_tab(tab, 'Research')
    assert.are.equal('Research', state.get_tab_name(tab))
  end)
end)

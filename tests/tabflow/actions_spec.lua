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
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_pinned')
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

  it('navigates according to the current mode', function()
    local tab = vim.api.nvim_get_current_tabpage()
    local b1 = vim.api.nvim_create_buf(false, true)
    local b2 = vim.api.nvim_create_buf(false, true)

    state.add_buffer(tab, b1)
    state.add_buffer(tab, b2)
    vim.api.nvim_set_current_buf(b1)

    actions.next_in_current_mode()
    assert.are.equal(b2, vim.api.nvim_get_current_buf())

    vim.cmd('tabnew')
    local second_tab = vim.api.nvim_get_current_tabpage()
    actions.enter_tabs_mode()
    actions.prev_in_current_mode()
    assert.are.equal(tab, vim.api.nvim_get_current_tabpage())
    assert.are_not.equal(second_tab, vim.api.nvim_get_current_tabpage())
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

  it('can pin and unpin a tab', function()
    local first_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('tabnew')
    local second_tab = vim.api.nvim_get_current_tabpage()

    actions.pin_tab(second_tab)

    local tabs = vim.api.nvim_list_tabpages()
    assert.is_true(state.is_tab_pinned(second_tab))
    assert.are.equal(second_tab, tabs[1])
    assert.are.equal(first_tab, tabs[2])

    actions.unpin_tab(second_tab)

    tabs = vim.api.nvim_list_tabpages()
    assert.is_false(state.is_tab_pinned(second_tab))
    assert.are.same({ second_tab, first_tab }, tabs)
  end)

  it('keeps pinned tabs before unpinned tabs during reorder', function()
    local first_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('tabnew')
    local second_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('tabnew')
    local third_tab = vim.api.nvim_get_current_tabpage()

    actions.pin_tab(first_tab)
    actions.reorder_tabs(third_tab, 1)

    local tabs = vim.api.nvim_list_tabpages()
    assert.are.equal(first_tab, tabs[1])
    assert.are.same({ first_tab, third_tab, second_tab }, tabs)
  end)

  it('does not close pinned tabs', function()
    local first_tab = vim.api.nvim_get_current_tabpage()
    vim.cmd('tabnew')
    local second_tab = vim.api.nvim_get_current_tabpage()

    actions.pin_tab(first_tab)
    actions.close_tab(first_tab)

    local tabs = vim.api.nvim_list_tabpages()
    assert.are.same({ first_tab, second_tab }, tabs)
    assert.is_true(state.is_tab_pinned(first_tab))
  end)
end)

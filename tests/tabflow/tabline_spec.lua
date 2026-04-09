local state = require('tabflow.state')
local tabline = require('tabflow.tabline')
local diagnostic_ns = vim.api.nvim_create_namespace('tabflow-tabline-spec')

describe('tabflow.tabline', function()
  before_each(function()
    state.state.mode = 'tabs'
    state.state.tabs = {}
    state.state.markers.modified = '●'
    state.state.markers.unmodified = ''
    state.state.markers.pinned = '[P]'
    state.state.diagnostics.enabled = true
    state.state.diagnostics.markers.error = 'E'
    state.state.diagnostics.markers.warn = 'W'
    state.state.diagnostics.markers.info = 'I'
    state.state.diagnostics.markers.hint = 'H'

    while #vim.api.nvim_list_tabpages() > 1 do
      vim.cmd('tabclose')
    end

    vim.diagnostic.reset(diagnostic_ns)

    local tab = vim.api.nvim_get_current_tabpage()
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_name')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_buffers')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_current')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'tabflow_pinned')
    pcall(vim.api.nvim_tabpage_del_var, tab, 'title')
  end)

  it('marks tab labels when the tab contains modified buffers', function()
    local first_tab = vim.api.nvim_get_current_tabpage()
    local first_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = first_buf })
    vim.api.nvim_buf_set_name(first_buf, vim.fn.tempname() .. '.lua')
    vim.api.nvim_buf_set_lines(first_buf, 0, -1, false, { 'modified' })

    state.rename_tab(first_tab, 'First')
    state.add_buffer(first_tab, first_buf)

    vim.cmd('tabnew')
    local second_tab = vim.api.nvim_get_current_tabpage()
    local second_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = second_buf })
    vim.api.nvim_buf_set_name(second_buf, vim.fn.tempname() .. '.lua')

    state.rename_tab(second_tab, 'Second')
    state.add_buffer(second_tab, second_buf)

    local items = tabline.build_items()

    assert.are.same('[TABS]', items[1].label)
    assert.are.equal('First ●', items[2].label)
    assert.are.equal('Second', items[3].label)
  end)

  it('uses the configured modified marker', function()
    state.state.markers.modified = '*'

    local first_tab = vim.api.nvim_get_current_tabpage()
    local first_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = first_buf })
    vim.api.nvim_buf_set_name(first_buf, vim.fn.tempname() .. '.lua')
    vim.api.nvim_buf_set_lines(first_buf, 0, -1, false, { 'modified' })

    state.rename_tab(first_tab, 'First')
    state.add_buffer(first_tab, first_buf)

    local items = tabline.build_items()

    assert.are.equal('First *', items[2].label)
  end)

  it('uses the configured unmodified marker', function()
    state.state.markers.unmodified = '-'

    local first_tab = vim.api.nvim_get_current_tabpage()
    local first_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = first_buf })
    vim.api.nvim_buf_set_name(first_buf, vim.fn.tempname() .. '.lua')

    state.rename_tab(first_tab, 'First')
    state.add_buffer(first_tab, first_buf)

    local items = tabline.build_items()

    assert.are.equal('First -', items[2].label)
  end)

  it('shows the pin marker for pinned tabs', function()
    local first_tab = vim.api.nvim_get_current_tabpage()
    local first_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = first_buf })
    vim.api.nvim_buf_set_name(first_buf, vim.fn.tempname() .. '.lua')

    state.rename_tab(first_tab, 'First')
    state.add_buffer(first_tab, first_buf)
    state.set_tab_pinned(first_tab, true)

    local items = tabline.build_items()

    assert.are.equal('First [P]', items[2].label)
  end)

  it('shows diagnostics for a buffer in buffers mode', function()
    state.state.mode = 'buffers'

    local tab = vim.api.nvim_get_current_tabpage()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. '.lua')

    state.add_buffer(tab, buf)
    vim.diagnostic.set(diagnostic_ns, buf, {
      { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = 'error' },
      { lnum = 0, col = 1, severity = vim.diagnostic.severity.WARN, message = 'warn' },
    })

    local items = tabline.build_items()

    assert.are.equal('[BUFFERS]', items[1].label)
    assert.are.equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t') .. ' E1 W1', items[2].label)
  end)

  it('aggregates diagnostics for a tab in tabs mode', function()
    local first_tab = vim.api.nvim_get_current_tabpage()
    local first_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = first_buf })
    vim.api.nvim_buf_set_name(first_buf, vim.fn.tempname() .. '.lua')

    state.rename_tab(first_tab, 'First')
    state.add_buffer(first_tab, first_buf)
    vim.diagnostic.set(diagnostic_ns, first_buf, {
      { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = 'error' },
      { lnum = 1, col = 0, severity = vim.diagnostic.severity.HINT, message = 'hint' },
    })

    local items = tabline.build_items()

    assert.are.equal('First E1 H1', items[2].label)
  end)

  it('can disable diagnostics display', function()
    state.state.mode = 'buffers'
    state.state.diagnostics.enabled = false

    local tab = vim.api.nvim_get_current_tabpage()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. '.lua')

    state.add_buffer(tab, buf)
    vim.diagnostic.set(diagnostic_ns, buf, {
      { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = 'error' },
    })

    local items = tabline.build_items()

    assert.are.equal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t'), items[2].label)
  end)
end)

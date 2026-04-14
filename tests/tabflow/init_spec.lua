local tabflow = require('tabflow')
local state = require('tabflow.state')

describe('tabflow.setup', function()
  local original_new_timer

  before_each(function()
    state.stop_right_section_timer()
    state.state.right_section = nil
    state.state.right_section_refresh_ms = nil

    original_new_timer = vim.uv.new_timer
  end)

  after_each(function()
    vim.uv.new_timer = original_new_timer
    state.stop_right_section_timer()
    state.state.right_section = nil
    state.state.right_section_refresh_ms = nil
  end)

  it('does not create a timer when refresh is unset', function()
    local created = 0
    vim.uv.new_timer = function()
      created = created + 1
      return {
        start = function() end,
        stop = function() end,
        close = function() end,
      }
    end

    tabflow.setup({
      right_section = function()
        return 'sync'
      end,
    })

    assert.are.equal(0, created)
    assert.is_nil(state.state.right_section_timer)
  end)

  it('does not create a timer when right_section is unset', function()
    local created = 0
    vim.uv.new_timer = function()
      created = created + 1
      return {
        start = function() end,
        stop = function() end,
        close = function() end,
      }
    end

    tabflow.setup({
      right_section_refresh_ms = 1000,
    })

    assert.are.equal(0, created)
    assert.is_nil(state.state.right_section_timer)
  end)

  it('creates a timer when right_section and refresh are configured', function()
    local starts = {}
    local timer = {
      start = function(_, timeout, repeat_interval, callback)
        table.insert(starts, { timeout = timeout, repeat_interval = repeat_interval, callback = callback })
      end,
      stop = function() end,
      close = function() end,
    }

    vim.uv.new_timer = function()
      return timer
    end

    tabflow.setup({
      right_section = function()
        return os.date(' %H:%M:%S ')
      end,
      right_section_refresh_ms = 1000,
    })

    assert.are.equal(1, #starts)
    assert.are.same({ timeout = 1000, repeat_interval = 1000, callback = starts[1].callback }, starts[1])
    assert.are.equal(timer, state.state.right_section_timer)
  end)

  it('replaces an existing timer on repeated setup', function()
    local stop_calls = 0
    local close_calls = 0
    local timers = {
      {
        start = function() end,
        stop = function()
          stop_calls = stop_calls + 1
        end,
        close = function()
          close_calls = close_calls + 1
        end,
      },
      {
        start = function() end,
        stop = function() end,
        close = function() end,
      },
    }
    local idx = 0

    vim.uv.new_timer = function()
      idx = idx + 1
      return timers[idx]
    end

    tabflow.setup({
      right_section = function()
        return 'one'
      end,
      right_section_refresh_ms = 1000,
    })
    tabflow.setup({
      right_section = function()
        return 'two'
      end,
      right_section_refresh_ms = 1000,
    })

    assert.are.equal(1, stop_calls)
    assert.are.equal(1, close_calls)
    assert.are.equal(timers[2], state.state.right_section_timer)
  end)
end)

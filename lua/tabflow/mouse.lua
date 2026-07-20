local state = require('tabflow.state')
local tabline = require('tabflow.tabline')

local M = {}

---@class TabflowDropData
---@field kind 'tab'|'buffer'
---@field source_id integer
---@field source_tab integer?
---@field source_index integer?
---@field hover_target? TabflowLayoutItem

---@return table?
local function get_mouse_on_tabline()
  local mouse = vim.fn.getmousepos()
  if mouse.screenrow ~= 1 then
    return nil
  end

  return mouse
end

---@return TabflowLayoutItem?, table?
local function get_tabline_item_under_mouse()
  local mouse = get_mouse_on_tabline()
  if not mouse then
    return nil, nil
  end

  return tabline.hit_test(mouse.screencol - 1), mouse
end

function M.setup()
  local maps = {
    ['<LeftMouse>'] = M.on_left_mouse,
    ['<MiddleMouse>'] = M.on_middle_mouse,
    ['<RightMouse>'] = M.on_right_mouse,
    ['<ScrollWheelDown>'] = function()
      M.on_scroll_wheel('down')
    end,
    ['<ScrollWheelUp>'] = function()
      M.on_scroll_wheel('up')
    end,
    ['<LeftDrag>'] = M.on_left_drag,
    ['<LeftRelease>'] = M.on_left_release,
  }

  for key, fn in pairs(maps) do
    vim.keymap.set('', key, function()
      fn()
      return key
    end, { expr = true })
  end
end

function M.on_left_mouse()
  local item, mouse = get_tabline_item_under_mouse()
  if not mouse then
    state.state.drag.pending = nil
    return
  end

  state.state.drag.active = false
  state.state.drag.pending = {
    item = item,
    start_mouse = { row = mouse.screenrow, col = mouse.screencol },
  }
end

function M.on_middle_mouse()
  local item = get_tabline_item_under_mouse()
  if item then
    vim.schedule(function()
      local actions = require('tabflow.actions')
      if item.kind == 'tab' then
        actions.close_tab(item.id)
      elseif item.kind == 'buffer' then
        actions.close_buffer(item.id)
      end
    end)
  end
end

function M.on_right_mouse()
  local item = get_tabline_item_under_mouse()
  if item and item.kind == 'tab' then
    vim.schedule(function()
      local actions = require('tabflow.actions')
      actions.prompt_rename_tab(item.id)
    end)
  end
end

function M.on_scroll_wheel(direction)
  if get_mouse_on_tabline() then
    local dir_val = (direction == 'down') and 1 or -1
    vim.schedule(function()
      local actions = require('tabflow.actions')
      local s = require('tabflow.state')
      actions.navigate(s.state.mode == 'tabs' and 'tab' or 'buffer', dir_val)
    end)
  end
end

function M.on_left_drag()
  local mouse = vim.fn.getmousepos()
  local drag = state.state.drag

  if drag.pending then
    local dx = math.abs(mouse.screencol - drag.pending.start_mouse.col)
    local dy = math.abs(mouse.screenrow - drag.pending.start_mouse.row)

    if not drag.active and (dx > 2 or dy > 0) then
      local item = drag.pending.item
      if item and (item.kind == 'tab' or item.kind == 'buffer') then
        drag.active = true
        drag.kind = item.kind
        drag.source_id = item.id
        drag.source_tab = vim.api.nvim_get_current_tabpage()
        drag.source_index = item.index
        drag.start_mouse = drag.pending.start_mouse

        -- Schedule ghost creation to avoid E565
        local label = item.label
        vim.schedule(function()
          M.create_ghost(label)
        end)
      end
    end
  end

  if drag.active then
    local item = tabline.hit_test(mouse.screencol - 1)

    if item and item.kind == 'mode_toggle' then
      vim.schedule(function()
        require('tabflow.actions').toggle_mode()
      end)
      drag.hover_target = nil
    else
      drag.hover_target = item
    end

    -- Schedule ghost update and redraw to avoid E565
    local col = mouse.screencol - 1
    vim.schedule(function()
      M.update_ghost(col)
      vim.cmd('redrawtabline')
    end)
  end
end

function M.on_left_release()
  local mouse = get_mouse_on_tabline()
  local drag = state.state.drag

  if drag.active then
    local drag_data = {
      kind = drag.kind,
      source_id = drag.source_id,
      source_tab = drag.source_tab,
      source_index = drag.source_index,
      hover_target = drag.hover_target,
    }
    vim.schedule(function()
      M.handle_drop_logic(drag_data)
      M.cleanup_ghost()
    end)
  elseif drag.pending then
    if mouse then
      local item = drag.pending.item
      if item then
        vim.schedule(function()
          local actions = require('tabflow.actions')
          if item.kind == 'mode_toggle' then
            actions.toggle_mode()
          elseif item.kind == 'tab' then
            -- tabs モードの場合は mode を変えずに tab だけ切り替える
            if state.state.mode == 'tabs' then
              vim.api.nvim_set_current_tabpage(item.id)
            else
              actions.switch_to_tab(item.id)
            end
          elseif item.kind == 'buffer' then
            actions.switch_to_buffer(item.id)
          end
        end)
      end
    end
  end

  drag.active = false
  drag.pending = nil
  vim.cmd('redrawtabline')
end

---@param label string
function M.create_ghost(label)
  local drag = state.state.drag
  if not drag.buffer or not vim.api.nvim_buf_is_valid(drag.buffer) then
    drag.buffer = vim.api.nvim_create_buf(false, true)
  end
  vim.api.nvim_buf_set_lines(drag.buffer, 0, -1, false, { label })

  drag.window = vim.api.nvim_open_win(drag.buffer, false, {
    relative = 'tabline',
    row = 0,
    col = 0,
    width = #label,
    height = 1,
    style = 'minimal',
    border = 'single',
    zindex = 250,
    mouse = false,
  })
  vim.api.nvim_set_option_value('winhl', 'Normal:IdeTablineHover', { win = drag.window })
end

---@param col integer
function M.update_ghost(col)
  local drag = state.state.drag
  if drag.window and vim.api.nvim_win_is_valid(drag.window) then
    vim.api.nvim_win_set_config(drag.window, {
      relative = 'tabline',
      row = 0,
      col = col,
    })
  end
end

function M.cleanup_ghost()
  local drag = state.state.drag
  if drag.window and vim.api.nvim_win_is_valid(drag.window) then
    vim.api.nvim_win_close(drag.window, true)
  end
  drag.window = nil
end

---@param data TabflowDropData
function M.handle_drop_logic(data)
  local actions = require('tabflow.actions')
  local target = data.hover_target

  if data.kind == 'tab' then
    if target and target.kind == 'tab' then
      actions.reorder_tabs(data.source_id, target.index)
    else
      local tab_handles = vim.api.nvim_list_tabpages()
      actions.reorder_tabs(data.source_id, #tab_handles)
    end
  elseif data.kind == 'buffer' then
    if target and target.kind == 'buffer' then
      if data.source_tab == vim.api.nvim_get_current_tabpage() then
        actions.reorder_buffers(data.source_tab, data.source_index, target.index)
      else
        actions.move_buffer_between_tabs(data.source_id, data.source_tab, vim.api.nvim_get_current_tabpage(), target.index)
      end
    elseif target and target.kind == 'tab' then
      actions.move_buffer_between_tabs(data.source_id, data.source_tab, target.id, nil)
    end
  end
end

return M

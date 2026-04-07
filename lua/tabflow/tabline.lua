local state = require('tabflow.state')

local M = {}

-- Get icon for a file
local function get_icon(bufnr, base_hl)
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
  if not has_devicons then
    return nil, nil
  end

  local full_path = vim.api.nvim_buf_get_name(bufnr)
  local filename = vim.fn.fnamemodify(full_path, ':t')
  local ext = vim.fn.fnamemodify(filename, ':e')
  local icon, color = devicons.get_icon_color(filename, ext, { default = true })

  local icon_hl = nil
  if color and state.state.icons.color then
    -- Generate a unique highlight group name based on color
    local hl_name = 'IdeTablineIcon' .. color:gsub('#', '')
    local base_attr = vim.api.nvim_get_hl(0, { name = base_hl, link = false })
    local bg = base_attr.bg or base_attr.background

    vim.api.nvim_set_hl(0, hl_name, { fg = color, bg = bg })
    icon_hl = hl_name
  end

  return icon, icon_hl
end

M.HL = {
  active = 'IdeTablineActive',
  inactive = 'IdeTablineInactive',
  fill = 'IdeTablineFill',
  separator = 'IdeTablineSeparator',
  modified = 'IdeTablineModified',
  hover = 'IdeTablineHover',
  icon_color = 'IdeTablineIconColor',
}

function M.render()
  local items = M.build_items()
  local tabline_str, layout_items = M.render_items(items)

  -- Save layout for hit-testing
  state.state.layout.items = layout_items
  state.state.layout.revision = state.state.layout.revision + 1

  return tabline_str
end

function M.build_items()
  local items = {}

  -- Add mode toggle with current workspace name context
  -- local current_tab = vim.api.nvim_get_current_tabpage()
  -- local workspace_name = state.get_tab_name(current_tab)
  -- local mode_label = (state.state.mode == 'tabs' and 'TABS' or ('WORKSPACE: ' .. workspace_name))
  local mode_label = (state.state.mode == 'tabs' and 'TABS' or 'BUFFERS')

  table.insert(items, {
    kind = 'mode_toggle',
    label = '[' .. mode_label .. ']',
  })

  if state.state.mode == 'tabs' then
    local tab_handles = vim.api.nvim_list_tabpages()
    local current_tab = vim.api.nvim_get_current_tabpage()

    for i, tab_handle in ipairs(tab_handles) do
      table.insert(items, {
        kind = 'tab',
        id = tab_handle,
        label = state.get_tab_name(tab_handle),
        active = tab_handle == current_tab,
        index = i,
      })
    end
  else
    local current_tab = vim.api.nvim_get_current_tabpage()
    local s = state.get_tab_state(current_tab)
    local current_buf = vim.api.nvim_get_current_buf()
    local util = require('tabflow.util')
    local labels = util.get_unique_labels(s.buffers)

    for i, bufnr in ipairs(s.buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        local label = labels[bufnr] or '[No Name]'
        if vim.api.nvim_get_option_value('modified', { buf = bufnr }) then
          label = label .. ' ●'
        end

        table.insert(items, {
          kind = 'buffer',
          id = bufnr,
          label = label,
          active = bufnr == current_buf,
          index = i,
        })
      end
    end
  end

  return items
end

function M.render_items(items)
  local total_width = vim.o.columns
  local res = ''
  local layout_items = {}
  local current_col = 0

  -- Separate mode toggle from other items
  local mode_toggle_item = nil
  local other_items = {}
  for _, item in ipairs(items) do
    if item.kind == 'mode_toggle' then
      mode_toggle_item = item
    else
      table.insert(other_items, item)
    end
  end

  -- 1. Render Mode Toggle on the left (Fixed)
  if mode_toggle_item then
    local hl = M.HL.inactive
    local label = ' ' .. mode_toggle_item.label .. ' '
    local width = vim.fn.strdisplaywidth(label)

    res = res .. '%#' .. hl .. '#' .. label

    table.insert(layout_items, {
      kind = mode_toggle_item.kind,
      label = mode_toggle_item.label,
      start_col = current_col,
      end_col = current_col + width,
      index = mode_toggle_item.index,
    })
    current_col = current_col + width
  end

  -- 2. Calculate widths and find active item for viewport logic
  local active_idx = 1
  for i, item in ipairs(other_items) do
    local hl = item.active and M.HL.active or M.HL.inactive
    local icon_char, icon_hl = nil, nil
    if item.kind == 'buffer' and item.id then
      icon_char, icon_hl = get_icon(item.id, hl)
    end

    item.icon_char = icon_char
    item.icon_hl = icon_hl
    local icon_str = icon_char and (icon_char .. ' ') or ''
    item.full_label = ' ' .. icon_str .. item.label .. ' '
    item.display_width = vim.fn.strdisplaywidth(item.full_label)
    if item.active then
      active_idx = i
    end
  end

  -- 3. Viewport logic: select a range of items that fits in the remaining space
  local available_width = total_width - current_col - 4 -- Small margin
  local start_idx = active_idx
  local end_idx = active_idx
  local items_width = (other_items[active_idx] and other_items[active_idx].display_width) or 0

  if #other_items > 0 then
    while true do
      local expanded = false
      -- Try to expand left
      if start_idx > 1 then
        local w = other_items[start_idx - 1].display_width
        if items_width + w + (start_idx > 2 and 3 or 0) <= available_width then
          start_idx = start_idx - 1
          items_width = items_width + w
          expanded = true
        end
      end
      -- Try to expand right
      if end_idx < #other_items then
        local w = other_items[end_idx + 1].display_width
        if items_width + w + (end_idx < #other_items - 1 and 3 or 0) <= available_width then
          end_idx = end_idx + 1
          items_width = items_width + w
          expanded = true
        end
      end
      if not expanded then
        break
      end
    end
  end

  -- 4. Render selected viewport range
  if #other_items > 0 then
    if start_idx > 1 then
      res = res .. '%#' .. M.HL.fill .. '#.. '
      current_col = current_col + 3
    elseif mode_toggle_item then
      res = res .. '%#' .. M.HL.separator .. '#│'
      current_col = current_col + 1
    end

    for i = start_idx, end_idx do
      local item = other_items[i]
      if item then
        local hl = item.active and M.HL.active or M.HL.inactive

        if i > start_idx then
          res = res .. '%#' .. M.HL.separator .. '#│'
          current_col = current_col + 1
        end

        if state.state.drag.active and state.state.drag.hover_target then
          if state.state.drag.hover_target.kind == item.kind and state.state.drag.hover_target.id == item.id then
            hl = M.HL.hover
          end
        end

        if item.icon_char and item.icon_hl then
          -- Re-check/re-set icon background if hl changed (e.g. hover)
          local icon_char, icon_hl = get_icon(item.id, hl)

          res = res .. '%#' .. hl .. '# ' -- leading space
          res = res .. '%#' .. icon_hl .. '#' .. icon_char
          res = res .. '%#' .. hl .. '# ' .. item.label .. ' ' -- icon-to-label space and rest
        else
          res = res .. '%#' .. hl .. '#' .. item.full_label
        end

        table.insert(layout_items, {
          kind = item.kind,
          id = item.id,
          label = item.label,
          start_col = current_col,
          end_col = current_col + item.display_width,
          index = item.index,
        })
        current_col = current_col + item.display_width
      end
    end

    if end_idx < #other_items then
      res = res .. '%#' .. M.HL.fill .. '# ..'
    end
  end

  -- Fill the rest
  res = res .. '%#' .. M.HL.fill .. '#%='

  return res, layout_items
end

-- Hit testing based on screen column
function M.hit_test(col)
  for _, item in ipairs(state.state.layout.items) do
    if col >= item.start_col and col < item.end_col then
      return item
    end
  end
  return nil
end

return M

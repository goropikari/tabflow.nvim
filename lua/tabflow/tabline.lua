local state = require('tabflow.state')

local M = {}

-- Get icon for a file
local function get_icon(bufnr)
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
  if not has_devicons then
    return nil
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local ext = vim.fn.fnamemodify(filename, ':e')
  local icon, color = devicons.get_icon_color(filename, ext, { default = true })
  return icon, color
end

M.HL = {
  active = 'IdeTablineActive',
  inactive = 'IdeTablineInactive',
  fill = 'IdeTablineFill',
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
  local res = ''
  local layout_items = {}
  local current_col = 0

  for i, item in ipairs(items) do
    local hl = M.HL.inactive
    if item.active then
      hl = M.HL.active
    end

    if state.state.drag.active and state.state.drag.hover_target then
      if state.state.drag.hover_target.kind == item.kind and state.state.drag.hover_target.id == item.id then
        hl = M.HL.hover
      end
    end

    -- Add icon for buffer items
    local icon = ''
    if item.kind == 'buffer' and item.id then
      local icon_char, icon_color = get_icon(item.id)
      if icon_char then
        icon = icon_char .. ' '
      end
    end

    local label = ' ' .. icon .. item.label .. ' '
    local start_col = current_col
    local item_len = #label
    local end_col = start_col + item_len

    res = res .. '%#' .. hl .. '#' .. label
    current_col = end_col

    table.insert(layout_items, {
      kind = item.kind,
      id = item.id,
      label = item.label,
      start_col = start_col,
      end_col = end_col,
      index = item.index,
    })
  end

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

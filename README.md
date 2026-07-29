# tabflow.nvim

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/goropikari/tabflow.nvim)

An IDE-style tabpage and buffer navigation plugin for Neovim 0.11+, using the tabline as a hierarchical interactive UI.

## 🚀 Features

- **Two-Level Navigation**:
  - **Tab Mode**: Manage workspaces (Neovim tab pages).
  - **Buffer Mode**: Manage file buffers belonging to the current workspace.
- **Git Integration**:
  - Automatically sets tab names to the git branch name for new tabs if you're in a git repository.
  - `:TabflowOpenWorktree <branch>`: Open an existing git worktree in a new tab using tab-local directory (`tcd`).
- **Full Mouse Support**:
  - **Left Click**: Switch tab/buffer or toggle modes.
  - **Middle Click**: Close tab or remove buffer from workspace.
  - **Right Click**: Rename tab.
  - **Drag & Drop**: Reorder tabs, reorder buffers, or move buffers between workspaces.- **Neovim 0.11+ Exclusive**:
  - Uses native `relative = "tabline"` floating windows for visual "ghost" drag feedback.
- **Smart Labels**:
  - Automatically disambiguates duplicate filenames by showing parent directory segments.
  - Supports `nvim-web-devicons` for file icons.
  - Can show diagnostic counts for buffers and tabs.
- **Workspace Aware**: Tracks "last active buffer" per tab page, restoring it when you switch back.

## 📋 Requirements

- **Neovim 0.11.0** or newer.
- A terminal emulator with mouse support.
- (Optional) [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) for file icons.

## 📦 Installation (lazy.nvim)

```lua
{
  "goropikari/tabflow.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- Optional, for icons
  opts = {
    markers = {
      modified = "●",
      unmodified = "",
      pinned = "[P]",
    },
    diagnostics = {
      enabled = true,
      markers = {
        error = "E",
        warn = "W",
        info = "I",
        hint = "H",
      },
    },
    -- Optional: Custom label formatter for full control over tab/buffer display
    label_formatter = function(item, ctx)
      -- item.type = 'tab' or 'buffer'
      -- item.name = base name
      -- item.markers = { pinned?, modified?, unmodified? }
      -- item.diagnostics = { error, warn, info, hint } (if enabled)
      -- item.icon = devicon (buffer mode only, if available)
      -- ctx.is_active = true if this is the active tab/buffer
      local parts = {}
      if item.icon then
        table.insert(parts, item.icon)
      end
      table.insert(parts, item.name)
      if item.markers.pinned then
        table.insert(parts, item.markers.pinned)
      end
      if item.markers.modified then
        table.insert(parts, item.markers.modified)
      end
      if item.diagnostics and item.diagnostics.error > 0 then
        table.insert(parts, 'E' .. item.diagnostics.error)
      end
      return table.concat(parts, ' ')
    end,

    -- Optional: Custom right-aligned tabline section
    right_section = function()
      return os.date(" %H:%M:%S ")
    end,
    -- Optional: redraw interval for right_section in milliseconds
    right_section_refresh_ms = 1000,
  },
}
```

`right_section` should return a raw tabline string. Return `nil` or `""` to hide it.
You can include statusline/tabline items such as `%#Highlight#` or `%{...}` when needed.
`right_section` is evaluated when the tabline redraws. For time-based content such as clocks, set
`right_section_refresh_ms` to opt into periodic `redrawtabline`.

## 🎮 Usage

### Mouse Interactions

- **Click** a tab or buffer to switch to it.
- **Click the `[TABS]` / `[BUFFERS]` indicator** to toggle display modes.
- **Middle-Click** an item to close it.
  - Pinned tabs must be unpinned before they can be closed.
- **Right-Click** a tab item to rename it.
- **Drag** an item to reorder it.
  - Dropping a buffer onto a different tab item moves that buffer to that workspace.
- **Mouse Wheel** (on tabline): Navigate between tabs or buffers.
  - In Tab mode: Switch between tabs.
  - In Buffer mode: Switch between buffers.
- `gt` / `gT`: Navigate to the next/previous tab in Tab mode, or the next/previous buffer in Buffer mode.

### Commands

- `:TabflowTabsMode`: Switch to Tab Page mode.
- `:TabflowBuffersMode`: Switch to Buffer mode.
- `:TabflowToggleMode`: Toggle between modes.
- `:TabflowNextTab` / `:TabflowPrevTab`: Navigate tabs.
- `:TabflowNextBuffer` / `:TabflowPrevBuffer`: Navigate buffers in current workspace.
- `:TabflowRenameTab <name>`: Rename the current workspace.
- `:TabflowTogglePinTab`: Toggle pin on the current workspace.
- `:TabflowPinTab`: Pin the current workspace.
- `:TabflowUnpinTab`: Unpin the current workspace.
- Pinned workspaces cannot be closed until unpinned.
- `:TabflowSetGitBranchName`: Set the current tab name to the git branch name.
- `:TabflowNewTab`: Create a new workspace.
- `:TabflowCloseTab`: Close the current workspace.
- `:TabflowCloseBuffer`: Remove the current buffer from the workspace.
- `:TabflowOpenWorktree <branch>`: Open an existing git worktree in a new tab for the specified branch.

## 🎨 Highlights

You can customize the look by overriding these highlight groups:

- `IdeTablineActive`: The active tab/buffer (links to `TabLineSel` by default).
- `IdeTablineInactive`: Inactive tabs/buffers (links to `TabLine` by default).
- `IdeTablineFill`: The empty space in the tabline (links to `TabLineFill` by default).
- `IdeTablineModified`: Marker for modified buffers (default: `#e0af68`).
- `IdeTablineHover`: The drop target or item being hovered during drag (links to `Visual` by default).

Example:

```lua
vim.api.nvim_set_hl(0, "IdeTablineActive", { fg = "#7aa2f7", bold = true, underline = true })
```

## 🔌 Lua API

You can use the following functions in your Lua configuration:

### Mode Switching

```lua
-- Get current mode ('tabs' or 'buffers')
require('tabflow.state').get_mode()

-- Switch to Tab mode
require('tabflow.actions').enter_tabs_mode()

-- Switch to Buffer mode
require('tabflow.actions').enter_buffers_mode()

-- Toggle between modes
require('tabflow.actions').toggle_mode()
```

### Navigation

```lua
-- Switch to next/previous tab
require('tabflow.actions').next_tab()
require('tabflow.actions').prev_tab()

-- Switch to next/previous buffer in current workspace
require('tabflow.actions').next_buffer()
require('tabflow.actions').prev_buffer()

-- Switch to a specific tab (by tab handle)
require('tabflow.actions').switch_to_tab(tab_handle)

-- Switch to a specific buffer (by bufnr)
require('tabflow.actions').switch_to_buffer(bufnr)
```

### Tab Management

```lua
-- Rename a tab
require('tabflow.actions').rename_tab(tab_handle, name)

-- Pin or unpin a tab
require('tabflow.actions').toggle_tab_pinned(tab_handle)
require('tabflow.actions').pin_tab(tab_handle)
require('tabflow.actions').unpin_tab(tab_handle)

-- Open rename prompt for a tab
require('tabflow.actions').prompt_rename_tab(tab_handle)

-- Close a tab (workspace)
require('tabflow.actions').close_tab(tab_handle)

-- Remove a buffer from current workspace
require('tabflow.actions').close_buffer(bufnr)

-- Open a git worktree in a new tab
require('tabflow.actions').select_worktree(branch_name) -- or nil for interactive selection
```

### Utility

```lua
-- Check if a buffer is in any tab
require('tabflow.actions').is_buffer_in_any_tab(bufnr)

-- Reorder tabs
require('tabflow.actions').reorder_tabs(source_tab, target_index)

-- Reorder buffers within a tab
require('tabflow.actions').reorder_buffers(tab_handle, source_index, target_index)

-- Move a buffer between tabs
require('tabflow.actions').move_buffer_between_tabs(bufnr, source_tab, target_tab, target_index)
```

### Formatter Helpers

```lua
local util = require('tabflow.util')

-- Format diagnostic counts into a string (e.g., "E2 W1")
util.format_diagnostics(counts, markers)

-- Combine label elements with proper spacing
util.combine_elements({ icon, name, marker, diagnostics })
```

### Example: Custom Keybindings

```lua
vim.keymap.set('n', '<leader>tt', require('tabflow.actions').toggle_mode, { desc = 'Toggle tab/buffer mode' })
vim.keymap.set('n', '<leader>tn', require('tabflow.actions').next_tab, { desc = 'Next tab' })
vim.keymap.set('n', '<leader>tp', require('tabflow.actions').prev_tab, { desc = 'Previous tab' })
vim.keymap.set('n', '<leader>bn', require('tabflow.actions').next_buffer, { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', require('tabflow.actions').prev_buffer, { desc = 'Previous buffer' })

-- Move left/right depending on current mode (tabs or buffers)
vim.keymap.set('n', '<C-A-h>', function()
  local state = require('tabflow.state')
  local actions = require('tabflow.actions')
  if state.get_mode() == 'tabs' then
    actions.prev_tab()
  else
    actions.prev_buffer()
  end
end, { desc = 'Move left (tab/buffer)' })

vim.keymap.set('n', '<C-A-l>', function()
  local state = require('tabflow.state')
  local actions = require('tabflow.actions')
  if state.get_mode() == 'tabs' then
    actions.next_tab()
  else
    actions.next_buffer()
  end
end, { desc = 'Move right (tab/buffer)' })
```

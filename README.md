# tabflow.nvim

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
  opts = {},
}
```

## 🎮 Usage

### Mouse Interactions

- **Click** a tab or buffer to switch to it.
- **Click the `[TABS]` / `[BUFFERS]` indicator** to toggle display modes.
- **Middle-Click** an item to close it.
- **Right-Click** a tab item to rename it.
- **Drag** an item to reorder it.
  - Dropping a buffer onto a different tab item moves that buffer to that workspace.
- **Mouse Wheel** (on tabline): Navigate between tabs or buffers.
  - In Tab mode: Switch between tabs.
  - In Buffer mode: Switch between buffers.

### Commands

- `:TabflowTabsMode`: Switch to Tab Page mode.
- `:TabflowBuffersMode`: Switch to Buffer mode.
- `:TabflowToggleMode`: Toggle between modes.
- `:TabflowNextTab` / `:TabflowPrevTab`: Navigate tabs.
- `:TabflowNextBuffer` / `:TabflowPrevBuffer`: Navigate buffers in current workspace.
- `:TabflowRenameTab <name>`: Rename the current workspace.
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

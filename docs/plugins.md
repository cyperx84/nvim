# Plugins

Managed by [lazy.nvim](https://github.com/folke/lazy.nvim). Each plugin lives in
its own file under `lua/custom/plugins/`. Run `:Lazy` to see the live list,
load state, and per-plugin triggers; `:Lazy profile` for load times.

## Load strategy

Plugins this config explicitly tunes for startup (see
[performance.md](performance.md)):

| Plugin | Loads on | File |
|--------|----------|------|
| harpoon | keypress (`<M-…>`) | `harpoon.lua` |
| git-worktree | keypress (`<leader>gw…`) | `git-worktree.lua` |
| opencode | keypress (`<leader>O…`, `go`) | `opencode.lua` |
| Navigator | keypress (`<C-h/j/k/l>`) | `tmux.lua` |
| gitsigns | file open (`BufReadPre`) | `gitsigns.lua` |
| indent-blankline | file open (`BufReadPost`) | `indent_line.lua` |
| nvim-highlight-colors | file open (`BufReadPost`) | `highlight-colors.lua` |
| vim-sleuth | file open (`BufReadPre`) | `lazy-plugins.lua` |
| lualine | `VeryLazy` | `lualine.lua` |
| uv.nvim | `VeryLazy` | `uv.lua` |
| supermaven | `InsertEnter` | `super-maven.lua` |
| fidget | `LspAttach` | `lspconfig.lua` |
| mason | command (`:Mason*`) | `lspconfig.lua` |

Kept eager on purpose: `tokyonight`, `transparent`, `snacks`, `oil`,
`nvim-treesitter`, `nvim-lspconfig`, `blink.cmp`. See
[performance.md](performance.md#what-is-intentionally-kept-eager-and-why).

## By category

### LSP & language support
- **nvim-lspconfig** — LSP server configuration (clangd, pyright,
  rust_analyzer, marksman, lua_ls)
- **mason / mason-lspconfig / mason-tool-installer** — install servers & tools
- **fidget** — LSP progress notifications
- **lazydev** — Lua/Neovim API completion for config editing
- **conform** — formatting
- **nvim-treesitter** — syntax highlighting & indentation (40+ parsers)

### Completion
- **blink.cmp** — completion engine (LSP, path, snippets, buffer)
- **friendly-snippets** — snippet collection

### AI assistance
- **CodeCompanion**, **Claude Code**, **Copilot**, **Supermaven**, **OpenCode**

### File navigation
- **oil.nvim** — edit the filesystem like a buffer
- **yazi** — TUI file manager
- **telescope** — fuzzy finder
- **harpoon** — quick file marks (harpoon2)

### Git
- **neogit** — full git UI
- **gitsigns** — gutter signs & hunk actions
- **git-worktree** — worktree management (via Telescope)

### UI / theme
- **tokyonight** — colorscheme
- **transparent** — transparent backgrounds
- **snacks** — dashboard, pickers, QoL utilities
- **lualine** — statusline
- **noice / nvim-notify** — UI for messages/cmdline/notifications
- **indent-blankline**, **nvim-highlight-colors**, **which-key**

### Markdown / notes
- **obsidian.nvim** — vault integration
- **render-markdown** / **markview** — in-buffer markdown rendering

### Navigation / editing
- **Navigator.nvim** — split/tmux pane navigation
- **neoscroll** — smooth, centered scrolling
- **mini.\***, **nvim-autopairs**, **nvim-ufo** (folding), **vim-sleuth**
  (indent detection)

> The exact set evolves — `:Lazy` is the source of truth.

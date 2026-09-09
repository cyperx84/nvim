# Plugins

Managed by Neovim's native [`vim.pack`](https://neovim.io/doc/user/pack.html)
via the loader in `lua/pack.lua` — no lazy.nvim. Each plugin lives in its own
file under `lua/plugins/`, auto-discovered at startup. See
[architecture.md](architecture.md) for the module contract and load model.

To inspect what's installed: `:lua = vim.pack.get()`. To update:
`:lua vim.pack.update()`. There is no `:Lazy`.

## Load strategy

Two kinds of deferral (full detail in [performance.md](performance.md)):

**Installed but not loaded until needed** (`data.lazy` + `require('pack').load`):

| Plugin(s) | Loads on | File |
|-----------|----------|------|
| harpoon (harpoon2) | first `<M-…>` harpoon key | `harpoon.lua` |
| git-worktree | first `<leader>gw…` key | `git-worktree.lua` |
| neogit + diffview | first Neogit `<leader>g…` key | `neo-git.lua` |
| img-clip | `<leader>pi` (paste image) | `image.lua` |
| nvim-dap stack | first DAP key | `debug.lua` |
| tokyonight, monokai-pro | colorscheme switch | `colorscheme.lua` |

**Loaded eagerly, config deferred** (`require('pack').defer(events, fn)` or an
inline autocmd):

| Plugin | Config runs on | File |
|--------|----------------|------|
| supermaven | `InsertEnter` | `super-maven.lua` |
| autopairs | `InsertEnter` | `autopairs.lua` |
| conform | `BufReadPre`/`BufNewFile` | `conform.lua` |
| gitsigns | `BufReadPre`/`BufNewFile` | `gitsigns.lua` |
| indent-blankline | `BufReadPost`/`BufNewFile` | `indent_line.lua` |
| nvim-highlight-colors | `BufReadPost`/`BufNewFile` | `highlight-colors.lua` |
| nvim-ufo | `BufReadPost` | `nvim-ufo.lua` |
| render-markdown | `FileType` | `render-markdown.lua` |
| fidget | `LspAttach` | `lspconfig.lua` |
| lualine, mini, uv, neoscroll, claude | `UIEnter` | (respective files) |
| which-key, todo-comments, telescope | `VimEnter` | (respective files) |

Kept eager on purpose: `colorscheme`/highlights, `transparent`, `snacks`,
`oil`, `nvim-treesitter`, `nvim-lspconfig` (`vim.lsp.enable`), `blink.cmp`. See
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
- **Claude Code**, **OpenCode**, **Supermaven**

### File navigation
- **oil.nvim** — edit the filesystem like a buffer (netrw replacement)
- **telescope** — fuzzy finder (+ fzf-native, ui-select)
- **harpoon** — quick file marks (harpoon2)

### Git
- **neogit** — full git UI
- **gitsigns** — gutter signs & hunk actions
- **git-worktree** — worktree management (via Telescope)

### UI / theme
- Active colorscheme is the built-in **`unokai`** (custom highlights in
  `colorscheme.lua`); **tokyonight** & **monokai-pro** are installed lazily as
  alternates
- **transparent** — transparent backgrounds
- **snacks** — dashboard, pickers, QoL utilities
- **lualine** — statusline
- **snacks.notifier** — messages/notifications UI (noice + nvim-notify retired 2025-08)
- **indent-blankline**, **nvim-highlight-colors**, **which-key**

### Markdown / notes
- **obsidian.nvim** — vault integration
- **render-markdown** — in-buffer markdown rendering
- **img-clip** (lazy) — paste images into notes

### Navigation / editing
- **herdr_nav** (`after/plugin/herdr_nav.lua`) — split/herdr/tmux pane navigation
- **neoscroll** — smooth, centered scrolling
- **mini.nvim** (ai/surround/sessions/pick/diff), **nvim-autopairs**, **nvim-ufo** (folding), **vim-sleuth**
  (indent detection)

> The exact set evolves — `lua/plugins/` and `:lua = vim.pack.get()` are the
> source of truth.

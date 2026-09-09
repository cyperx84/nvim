# Architecture

How this config is organized and the order things load. The plugin layer is
built on Neovim's native [`vim.pack`](https://neovim.io/doc/user/pack.html)
(Neovim 0.12+) — there is no lazy.nvim, packer, or other plugin manager. A
~300-line loader in `lua/pack.lua` adds the conveniences a manager usually
provides (auto-discovery, on-demand loading, build hooks).

## Repository layout

```
~/.config/nvim/                 ← this repo (clone directly here)
├── init.lua                    ← entry point; load order lives here
├── lua/
│   ├── options.lua             ← vim.opt settings
│   ├── keymaps.lua             ← global, plugin-independent keymaps
│   ├── autocmds.lua            ← global autocommands
│   ├── pack.lua                ← the plugin loader (vim.pack wrapper)
│   ├── plugins/                ← one file per plugin (or group); auto-discovered
│   │   └── *.lua               ←   each returns { specs = {...}, config = fn }
│   └── custom/                 ← standalone helpers (not plugin modules)
├── patches/                    ← local .patch files applied to plugins
├── scripts/                    ← helpers (Obsidian link/tag extraction, smoke test)
├── docs/                       ← this documentation
├── nvim-pack-lock.json         ← pinned plugin versions (tracked in git)
└── README.md
```

## Load order (`init.lua`)

```lua
vim.g.boot_hrtime = vim.uv.hrtime()  -- 0. stamp boot time (dashboard footer)
vim.loader.enable()                  -- 1. Lua bytecode cache (before any require)
vim.g.mapleader = ' '                -- 2. leaders (before plugins/keymaps load)
require 'options'                    -- 3. editor options
require 'keymaps'                    -- 4. global keymaps
require 'autocmds'                   -- 5. global autocommands
require 'pack'                       -- 6. install plugins + run each config()
```

Leaders are set first because `<leader>…` keymaps are resolved against
`mapleader` at registration time. `vim.loader.enable()` must run before any
`require` so module bytecode is served from cache.

## The plugin loader (`lua/pack.lua`)

Each file in `lua/plugins/` returns a module with two fields:

```lua
local M = {}
M.specs = {                                   -- what to install (vim.pack specs)
  { src = 'https://github.com/author/plugin.nvim' },
}
function M.config() ... end                   -- runtime setup, run in load order
return M
```

`pack.lua` does four things, all guarded so one bad module can't abort the rest:

1. **Discover** every `lua/plugins/*.lua` module (`nvim_get_runtime_file`).
2. **Collect & dedupe** all `M.specs` into a single `vim.pack.add()` call.
   Plugins declared by more than one module are merged: a version pin or build
   hook on a duplicate is preserved, and laziness must be unanimous (one eager
   declaration makes the plugin eager).
3. **Split eager vs lazy** — specs with `data.lazy = true` are installed with a
   no-op load function, so they stay off the runtimepath until requested.
4. **Run each `config()`** in load order, each wrapped in `pcall`.

### Spec conventions (`spec.data`)

`vim.pack` specs accept `src`, `version`, and `name`. This config adds its own
`data` table on top:

| Field        | Effect |
|--------------|--------|
| `data.lazy`  | Install but don't load at startup (no runtimepath entry, no `plugin/` sourcing). Load on demand with `require('pack').load{ 'name' }`. |
| `data.build` | Build hook, run by the `PackChanged` autocmd on install/update: `':Cmd'` (ex-command), `'shell cmd'` (run in the plugin dir), or a function. |

### Load order

Modules run **alphabetically**, with a few pinned for real ordering
constraints (see the comment block in `pack.lua`):

| Position | Modules | Why |
|----------|---------|-----|
| First | `colorscheme`, `snacks` | Theme/highlights before first paint; snacks owns the dashboard splash + terminal provider others reuse |
| Last | `debug`, `sleuth` | DAP needs `mason` (from lspconfig) set up first; sleuth should observe options set by everything else |
| Middle | everything else | Alphabetical (`cmp` < `lspconfig` keeps completion capabilities ready before LSP) |

## On-demand & deferred loading

Three mechanisms, no framework:

**1. `data.lazy` + `require('pack').load{...}`** — installed but unloaded until
the first time a keymap/command needs it. `load` is idempotent and `packadd`s
each plugin at most once.

| Plugin(s) | Loaded by |
|-----------|-----------|
| `harpoon` (harpoon2) | first `<M-…>` harpoon key |
| `git-worktree.nvim` | first `<leader>gw…` key |
| `neogit` + `diffview.nvim` | first Neogit `<leader>g…` key |
| `img-clip.nvim` | `<leader>pi` (paste image) |
| `nvim-dap` + dap-ui/nio/mason-nvim-dap/dap-go | first DAP key |
| `tokyonight`, `monokai-pro` | only if you switch colorscheme |

**2. `require('pack').defer(events, fn)`** — registers a one-shot autocmd that
loads-and-configures on the first matching event, then **re-fires that event on
every already-open buffer** so multi-file startups (`nvim a.lua b.lua`, restored
sessions) still run per-buffer setup. `opts.pattern` can gate it (e.g. a
specific FileType).

| Trigger | Modules |
|---------|---------|
| `InsertEnter` | autopairs, supermaven |
| `BufReadPre`/`BufNewFile` | conform, gitsigns |
| `BufReadPost`/`BufNewFile` | indent-blankline, nvim-highlight-colors, nvim-ufo |
| `FileType` | render-markdown, lspconfig (highlight setup) |
| `LspAttach` | fidget (LSP progress UI) |
| `UIEnter` | mini, uv (neoscroll/lualine/claude inline) |
| `VimEnter` | which-key, todo-comments |

**3. Inline `UIEnter`/`VimEnter` autocmds** — a handful of modules register
their own deferral instead of using `defer()` (their setup has no per-buffer
re-fire need): `claude`, `lualine`, `neoscroll` (UIEnter), and
`telescope` (VimEnter).

Everything not listed above loads eagerly at startup — see
[performance.md](performance.md) for which, and why.

> **Note on LSP:** `lspconfig`'s module *config* is split — `vim.lsp.enable(...)`
> runs eagerly so servers attach to the first file immediately, while the
> document-highlight setup defers to `FileType`, fidget to `LspAttach`, and the
> Mason installer machinery to `vim.schedule` (off the startup path).

## Build hooks

Declared via `data.build` and executed by the `PackChanged` autocmd in
`pack.lua` whenever a plugin is installed or updated:

- `telescope-fzf-native.nvim` → `make` (compiles the native sorter)
- `nvim-treesitter` → `:TSUpdate` (updates parsers)

## Patches

`patches/` holds `.patch` files applied to upstream plugins for local fixes,
with `.guard` files tracking applied state. Re-apply after a plugin update if a
patched behavior regresses.

## Updating plugins

There is no `:Lazy`. Use `vim.pack` directly:

```vim
:lua vim.pack.update()            " update all (opens a confirm buffer)
:lua vim.pack.update({ 'name' })  " update one
:lua = vim.pack.get()             " list installed plugins + versions
:checkhealth vim.pack             " diagnose the plugin store
```

Commit `nvim-pack-lock.json` afterward to keep installs reproducible.

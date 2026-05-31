# Architecture

How this config is organized and the order things load.

## Repository layout

```
~/.config/nvim/                 ← this repo (clone directly here)
├── init.lua                    ← entry point; load order lives here
├── lua/
│   ├── options.lua             ← vim.opt settings
│   ├── keymaps.lua             ← global, plugin-independent keymaps
│   ├── autocmds.lua            ← global autocommands
│   ├── lazy-bootstrap.lua      ← clones lazy.nvim if missing
│   ├── lazy-plugins.lua        ← lazy.setup() + performance opts
│   └── custom/
│       └── plugins/            ← one file per plugin (or plugin group)
├── patches/                    ← local patches applied to plugins
├── scripts/                    ← helper scripts (Obsidian link/tag extraction)
├── docs/                       ← this documentation
├── lazy-lock.json              ← pinned plugin versions (gitignored)
└── README.md
```

## Load order (`init.lua`)

```lua
vim.loader.enable()      -- 1. Lua bytecode cache (before any require)
vim.g.mapleader = ' '    -- 2. leaders (must be set before plugins/keymaps)
require 'options'        -- 3. editor options
require 'keymaps'        -- 4. global keymaps
require 'autocmds'       -- 5. global autocommands
require 'lazy-bootstrap' -- 6. ensure lazy.nvim is installed
require 'lazy-plugins'   -- 7. lazy.setup() → plugins load per their triggers
```

Leaders are set first because lazy-loaded `<leader>…` keymaps are resolved
against `mapleader` at registration time.

## Plugin specs

`lazy-plugins.lua` calls:

```lua
require('lazy').setup({
  { 'tpope/vim-sleuth', event = { 'BufReadPre', 'BufNewFile' } },
  { import = 'custom.plugins' },   -- auto-imports every file in custom/plugins/
}, { performance = { rtp = { disabled_plugins = { ... } } }, ui = { ... } })
```

Each file in `lua/custom/plugins/` returns a lazy.nvim plugin spec (a table, or
a list of tables). To add a plugin, drop a new `.lua` file there — no central
registry to edit. See [Customization](../README.md#-customization).

## Load triggers (lazy-loading)

Plugins declare *when* they load. See [performance.md](performance.md) for the
full breakdown, but the vocabulary:

| Field | Loads when… |
|-------|-------------|
| (none) / `lazy = false` | at startup |
| `event` | a Vim event fires (`BufReadPre`, `InsertEnter`, `LspAttach`, `VeryLazy`, …) |
| `keys` | a mapped key is pressed |
| `cmd` | an Ex command is run |
| `ft` | a matching filetype opens |
| `dependencies` | its parent plugin loads |

## Patches

`patches/` holds `.patch` files applied to upstream plugins for local fixes.
The `.guard` files track which patch state is applied. Re-apply after a plugin
update if a patched behavior regresses.

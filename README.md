# Neovim Configuration

```
            ▄████▄  ▓██   ██▓ ██▓███  ▓█████  ██▀███  ▒██   ██▒
           ▒██▀ ▀█   ▒██  ██▒▓██░  ██▒▓█   ▀ ▓██ ▒ ██▒▒▒ █ █ ▒░
           ▒▓█    ▄   ▒██ ██░▓██░ ██▓▒▒███   ▓██ ░▄█ ▒░░  █   ░
           ▒▓▓▄ ▄██▒  ░ ▐██▓░▒██▄█▓▒ ▒▒▓█  ▄ ▒██▀▀█▄   ░ █ █ ▒
           ▒ ▓███▀ ░  ░ ██▒▓░▒██▒ ░  ░░▒████▒░██▓ ▒██▒▒██▒ ▒██▒
           ░ ░▒ ▒  ░   ██▒▒▒ ▒▓▒░ ░  ░░░ ▒░ ░░ ▒▓ ░▒▓░▒▒ ░ ░▓ ░
             ░  ▒    ▓██ ░▒░ ░▒ ░      ░ ░  ░  ░▒ ░ ▒░░░   ░▒ ░
           ░         ▒ ▒ ░░  ░░          ░     ░░   ░  ░    ░
           ░ ░       ░ ░                 ░  ░   ░      ░    ░
           ░         ░ ░
```

A personal Neovim config for **Neovim 0.12+**, built around the native
[`vim.pack`](https://neovim.io/doc/user/pack.html) plugin manager — no
lazy.nvim, no packer. A small custom loader (`lua/pack.lua`) adds the parts of a
plugin manager that are actually worth having (auto-discovery, on-demand
loading, build hooks, a lockfile) in ~300 lines you can read in one sitting.

Originally forked from [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim),
it has since been rewritten: native LSP enablement (`vim.lsp.enable`), the
Treesitter `main`-branch API, and a from-scratch plugin loader.

> **Requires Neovim 0.12** (currently nightly). It uses `vim.pack`,
> `vim.lsp.enable`/`vim.lsp.config`, `vim.o.winborder`, and the rewritten
> Treesitter API — none of which exist on 0.11 or earlier.

---

## What makes this config different

- **Native `vim.pack`, not a plugin manager.** Plugins are declared as
  `{ src = 'https://github.com/...' }` specs and installed by Neovim itself.
  The loader in `lua/pack.lua` collects every module's specs into one
  `vim.pack.add()` call, dedupes them, and runs each module's `config()`.
- **Drop-a-file plugins.** Every file in `lua/plugins/` is auto-discovered.
  Adding a plugin = creating one file. There is no central list to edit and no
  "I forgot to register it" failure mode.
- **On-demand loading without a framework.** Plugins marked `data.lazy = true`
  are installed but kept off the runtimepath until something calls
  `require('pack').load{...}`. The `require('pack').defer(events, fn)` helper
  loads-and-configures a plugin the first time a chosen event fires — and
  re-fires that event on already-open buffers, so opening files on the command
  line (`nvim a.lua b.lua`) still triggers per-buffer setup correctly.
- **Tuned for first paint.** Lua bytecode caching (`vim.loader.enable()`),
  deferred plugin config past `UIEnter`, and a fast splash bring the TUI to
  first paint in **~90 ms** (down from ~450 ms). The dashboard footer shows the
  live boot time.
- **Reproducible.** Versions are pinned in `nvim-pack-lock.json`.

---

## Quick start

### Prerequisites

```bash
# Neovim 0.12+ (nightly) and the search/find tools used by Telescope & Oil
brew install --HEAD neovim          # or: brew install neovim (when 0.12 is stable)
brew install git ripgrep fd fzf

# Recommended
brew install imagemagick            # inline image rendering (img-clip / snacks)
brew install trash                  # Oil deletes to trash instead of rm
```

External CLIs for the AI integrations (optional, only if you use them):

- `claude` — [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI,
  expected at `~/.local/bin/claude`
- `opencode` — [OpenCode](https://github.com/sst/opencode) CLI on your `PATH`

### Install

```bash
git clone <this-repo> ~/.config/nvim
nvim
```

On first launch `vim.pack` clones every plugin (one-time, a minute or two),
Mason installs the configured LSP servers and `stylua`, and Treesitter parsers
build on first file open. **The first launch is always the slow one** — the Lua
bytecode cache and parsers are cold. Restart once and you get the real startup
time.

---

## Layout

```
~/.config/nvim/
├── init.lua                 # entry point — sets leader, enables loader cache,
│                            #   then requires: options → keymaps → autocmds → pack
├── lua/
│   ├── options.lua          # vim.opt settings
│   ├── keymaps.lua          # global, plugin-independent keymaps
│   ├── autocmds.lua         # global autocommands
│   ├── pack.lua             # THE plugin loader (vim.pack wrapper)
│   ├── plugins/             # one file per plugin/group — auto-discovered
│   │   ├── lspconfig.lua    #   each returns { specs = {...}, config = fn }
│   │   ├── claude.lua
│   │   ├── oil.lua
│   │   └── … (37 modules)
│   └── custom/              # standalone helpers (e.g. milli_follow)
├── nvim-pack-lock.json      # pinned plugin versions
└── docs/                    # deep-dive docs (keybindings, plugins, …)
```

### How a plugin module works

Each file in `lua/plugins/` returns a table with two fields:

```lua
local M = {}

-- 1. What to install. Plain vim.pack specs.
M.specs = {
  { src = 'https://github.com/author/plugin.nvim' },
  -- data.lazy = installed but NOT loaded at startup; load it on demand later.
  { src = 'https://github.com/author/heavy.nvim', data = { lazy = true } },
}

-- 2. Runtime setup. Runs after all specs are added, in load order.
function M.config()
  require('plugin').setup {}
  vim.keymap.set('n', '<leader>x', '<cmd>DoThing<cr>', { desc = 'Do thing' })
end

return M
```

`spec.data` is this config's own convention on top of `vim.pack`:

| Field        | Effect |
|--------------|--------|
| `data.lazy`  | Install the plugin but keep it off the runtimepath until `require('pack').load{ 'name' }`. |
| `data.build` | Build hook run on install/update: `':Cmd'` (ex-command), `'shell cmd'`, or a function. |

To defer setup until a plugin is first needed:

```lua
-- Load + configure on the first InsertEnter, BufReadPre, FileType lua, etc.
require('pack').defer('InsertEnter', function()
  require('supermaven-nvim').setup {}
end)
```

Load order is alphabetical except for a few pinned constraints documented at the
top of `lua/pack.lua` (`colorscheme` and `snacks` first; `debug` and `sleuth`
last). A malformed spec or a failing `config()` is caught per-module — one
broken plugin won't take down the rest of your editor.

---

## Managing plugins

This config uses `vim.pack` directly — there is **no `:Lazy`**.

```vim
:lua vim.pack.update()          " update all plugins (opens a confirm buffer)
:lua vim.pack.update({ 'name' }) " update one
:lua = vim.pack.get()           " list installed plugins + versions
:checkhealth vim.pack           " diagnose the plugin store
```

Commit `nvim-pack-lock.json` after updating to keep installs reproducible.

---

## Feature tour

### AI assistants

| Tool | Trigger | Notes |
|------|---------|-------|
| **Claude Code** ([claudecode.nvim](https://github.com/coder/claudecode.nvim)) | `<M-;>` toggle | Runs the `claude` CLI in a Snacks terminal split (right, 35%). Auto-opens diffs in a vertical split; buffers auto-reload on external edits. |
| **OpenCode** ([opencode.nvim](https://github.com/NickvanDyke/opencode.nvim)) | `<M-'>` toggle | `<leader>Oa` ask about the current line/selection, `<leader>Ox` pick an action, `go`/`goo` send a range/line. |
| **Supermaven** ([supermaven-nvim](https://github.com/supermaven-inc/supermaven-nvim)) | inline (on `InsertEnter`) | `<C-y>` accept, `<C-j>` accept word, `<C-]>` clear. |

Claude Code buffer/selection commands: `<leader>cb` add buffer, `<leader>cB`
add all buffers, `<leader>cs` send selection (visual), `<leader>cm` pick model,
`<leader>cr` resume, `<leader>cC` continue.

### LSP, completion & formatting

- **LSP** via native `vim.lsp.enable` (no lspconfig framework setup): `lua_ls`,
  `pyright`, `rust_analyzer`, `clangd`, `marksman`. Servers are installed with
  **Mason**, whose machinery is deferred off the startup path.
- **Completion** — [blink.cmp](https://github.com/saghen/blink.cmp) (Rust fuzzy
  matcher), sourcing LSP / path / snippets / buffer.
- **Formatting** — [conform.nvim](https://github.com/stevearc/conform.nvim),
  `<leader>l` to format (LSP fallback). Configured: stylua (Lua),
  prettier/prettierd (JS/TS/JSON/CSS/Svelte/Astro/GraphQL/Markdown), rustfmt,
  gofmt, shfmt, taplo (TOML), yamlfix, htmlbeautifier, buf, xmllint.
- **Treesitter** — `main`-branch API, 40+ parsers, kept eager for highlighting
  on the first buffer.
- **Folding** — [nvim-ufo](https://github.com/kevinhwang91/nvim-ufo) backed by
  LSP folding ranges.

### Files, search & navigation

- **Oil** (`<C-e>`) — edit the filesystem like a buffer; deletes to trash, runs
  LSP-aware file ops. (`-` goes to the parent dir inside an Oil buffer.)
- **Telescope** (`<leader>s…`) — fuzzy finder with fzf-native + ui-select.
- **Harpoon 2** — `<M-a>` mark, `<M-e>` menu, `<M-j/k/l>` jump to files 1–3,
  `<M-u/i/o>` 4–6, `<M-7/8/9>` 7–9.
- **Navigator.nvim** — `<C-h/j/k/l>` moves seamlessly across Neovim splits and
  tmux panes.
- **neoscroll** — smooth, auto-centered half-page scrolling.

### Git

- **Neogit** (`<leader>gg` float, `<leader>gG` split) + branch/commit/diff/log/
  stash/merge/push/pull under `<leader>g…`, with diffview integration.
- **gitsigns** — gutter signs, hunk staging, `]c`/`[c` navigation, `<leader>tb`
  blame line.
- **git-worktree** — `<leader>gwl` list (`<C-d>` to delete), `<leader>gwc`
  create; Telescope-driven.

### Notes (Obsidian)

[obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) with iCloud
vaults and auto-reload, under `<leader>o…`: `on` new, `of` find, `od` daily,
`os` search, `ob` backlinks, `oF` follow link, `oi` paste image, `ow` switch
workspace. Live in-buffer rendering via
[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim).

### UI

- Colorscheme: the built-in **`unokai`** with custom magenta float/border
  highlights (TokyoNight and Monokai Pro are installed lazily to switch to).
- **transparent.nvim** — global background transparency with float handling.
- **snacks.nvim** — dashboard (with live boot-time footer), pickers, zen mode
  (`<leader>tz`), and the terminal provider Claude Code / OpenCode reuse.
- **lualine** statusline, **noice** + **nvim-notify** for messages/cmdline.

### Sessions (mini.sessions)

`<leader>Ss` save (named), `<leader>Sw` save current, `<leader>Sl` pick & load,
`<leader>Sn` notes, `<leader>Sd` dotfiles, `<leader>Sc` code, `<leader>Sx`
delete.

---

## Essential keybindings

Leader is `Space`. **which-key** shows live hints — press `<leader>` and wait.

| Key | Action |
|-----|--------|
| `<C-e>` | Toggle Oil file explorer |
| `<leader>sf` / `<leader>sg` | Find files / live grep (Telescope) |
| `<leader><leader>` | Find open buffers |
| `<C-h/j/k/l>` | Move across splits / tmux panes |
| `<M-a>` / `<M-e>` | Harpoon: mark file / toggle menu |
| `gd` / `gr` / `gI` | LSP goto definition / references / implementation |
| `<leader>rn` / `<leader>ca` | Rename symbol / code action |
| `<leader>l` | Format buffer or selection |
| `<leader>gg` | Open Neogit |
| `<M-;>` / `<M-'>` | Toggle Claude Code / OpenCode |
| `<C-s>` / `<C-q>` | Save / quit |
| `jk` | Exit insert mode |

**Full reference:** [`docs/keybindings.md`](docs/keybindings.md).

---

## Documentation

| Doc | Contents |
|-----|----------|
| [`docs/keybindings.md`](docs/keybindings.md) | Complete keymap reference by group |
| [`docs/plugins.md`](docs/plugins.md) | The plugin set and how each one loads |
| [`docs/architecture.md`](docs/architecture.md) | Repo layout and load order |
| [`docs/performance.md`](docs/performance.md) | Startup tuning: lazy vs eager, profiling |

> The authoritative answer for *which* plugins exist and *when* they load is
> always the files in `lua/plugins/` and the loader in `lua/pack.lua` —
> `:lua = vim.pack.get()` lists what's actually installed.

---

## Troubleshooting

**A plugin didn't load.** Lazy plugins (`data.lazy`) and `defer()`-ed setups
load on a trigger — if the trigger never fired, nothing errors, the feature is
just absent. Confirm the plugin is on the runtimepath with `:lua = vim.pack.get()`
and check the event/keymap that should load it.

**LSP not attaching.** `:checkhealth lsp`, `:LspInfo`, `:Mason` (is the server
installed?), then `:LspRestart`. Logs: `:lua vim.cmd('e ' .. vim.lsp.get_log_path())`.

**Telescope / live grep finds nothing.** Install the CLIs: `brew install ripgrep fd`.

**Oil won't delete to trash.** `brew install trash`.

**Slow startup.** Profile the *second* launch (the first rebuilds caches):
`nvim --startuptime /tmp/st.log` then `sort -k2 -nr /tmp/st.log | head -20`.

**General health:** `:checkhealth` (and `:checkhealth vim.pack`).

---

**Maintained by:** cyperx · Built on Neovim 0.12 native APIs.

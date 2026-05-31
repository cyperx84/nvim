# Startup Performance

This config is tuned for fast startup. Warm startup is **~55 ms** (headless
`--startuptime` median), down from ~102 ms before tuning.

> Numbers from `nvim --headless --startuptime` are *directional* — they skip
> some UI-gated work. Your real interactive startup will differ in absolute
> value but moves the same direction.

## How to measure

```bash
# Capture a startup profile
nvim --headless --startuptime /tmp/st.log -c 'qa!'

# Top time sinks
sort -k2 -nr /tmp/st.log | head -20

# Or, inside Neovim, see per-plugin load + config time:
:Lazy profile
```

The first launch after a config change is always slower — the Lua bytecode
cache (`vim.loader`) and treesitter parsers rebuild. Measure the **second**
launch.

## The levers used here

1. **`vim.loader.enable()`** (top of `init.lua`) — caches compiled Lua module
   bytecode under `~/.cache/nvim/luac/`. Single biggest win; must run before
   any `require`.
2. **Lazy-loading** via lazy.nvim triggers — plugins load on demand instead of
   at startup:
   - **on keypress** (`keys`): harpoon, git-worktree (also frees telescope,
     ~14 ms), opencode, Navigator
   - **on file open** (`event = BufReadPre/BufReadPost/BufNewFile`): gitsigns,
     indent-blankline, nvim-highlight-colors, vim-sleuth
   - **`VeryLazy`** (after the first frame): lualine, uv.nvim
   - **`InsertEnter`**: supermaven (inline AI completion)
   - **`LspAttach`**: fidget (LSP progress UI)
   - **command** (`cmd`): mason (`:Mason*`)
3. **Deferred work in `config()`** — lspconfig stays eager (so LSP attaches to
   the first file immediately via `vim.lsp.enable`), but the Mason installer
   machinery (`mason-tool-installer` / `mason-lspconfig` setup) is wrapped in
   `vim.schedule(...)` so the package-registry load happens just *after*
   startup instead of during it.
4. **Disabled built-in runtime plugins** (`performance.rtp.disabled_plugins` in
   `lua/lazy-plugins.lua`): `gzip`, `matchit`, `tarPlugin`, `zipPlugin`,
   `tohtml`, `tutor`, `netrwPlugin` (Oil/Yazi replace netrw).

## What is intentionally kept eager (and why)

| Plugin | Why it stays eager |
|--------|--------------------|
| `tokyonight.nvim` | Colorscheme — must apply before the first paint |
| `transparent.nvim` | Must apply early or the background flashes |
| `snacks.nvim` | Paints the dashboard / splash at startup |
| `oil.nvim` | Now the netrw replacement; must handle directory args |
| `nvim-treesitter` | Highlighting on the first buffer (kept eager by choice) |
| `nvim-lspconfig` | LSP attaches to the first file immediately (by choice) |
| `blink.cmp` | Pulled in by lspconfig via `get_lsp_capabilities()`; can't be
  deferred without also deferring lspconfig |

The largest remaining cost is `blink.cmp` (~20 ms across its modules), locked to
eager lspconfig. To reclaim it you would defer lspconfig itself
(`event = { 'BufReadPre', 'BufNewFile' }`) and compute capabilities lazily —
a deliberate trade-off not taken here.

## Gotchas worth remembering

- A `keys`/`cmd`/`event` trigger that never fires means the feature silently
  doesn't work — there is **no startup error**. After changing a trigger,
  actually press the key / open the file type and confirm the plugin loads
  (`:Lazy` shows load state).
- Adding a plugin as a hard `dependencies` entry makes it load whenever its
  parent loads. If the parent is eager, the dependency is effectively eager too
  (this is why Mason was moved out of `nvim-lspconfig`'s `dependencies`).

# Startup Performance

This config is tuned for fast **first paint** — the moment the dashboard is
visible and interactive. TUI first paint is **~89 ms**, down from ~452 ms before
tuning. The dashboard footer shows the live boot time for the current launch
(stamped from `vim.g.boot_hrtime` in `init.lua`).

> Two different numbers measure two different things, don't compare them:
> - **TUI first paint** (~89 ms) — what you actually wait for; measured from
>   `boot_hrtime` to the first rendered frame.
> - **`nvim --headless --startuptime`** — a lower, *directional* number that
>   skips UI-gated work. Useful for spotting regressions, not for the felt
>   latency.

## How to measure

```bash
# Headless startup profile (directional — good for diffing changes)
nvim --headless --startuptime /tmp/st.log -c 'qa!'
sort -k2 -nr /tmp/st.log | head -20      # top time sinks

# Real TUI first paint: just launch — the dashboard footer prints it.
```

There is **no `:Lazy profile`** (no lazy.nvim). To see what's installed and its
version: `:lua = vim.pack.get()`.

**Always measure the *second* launch.** The first after a config change is
always slower — the Lua bytecode cache (`vim.loader`) and Treesitter parsers
rebuild.

## The levers used here

1. **`vim.loader.enable()`** (top of `init.lua`, before any `require`) — caches
   compiled Lua module bytecode under `~/.cache/nvim/luac/`. Single biggest win.

2. **Native `vim.pack` with no manager overhead** — plugins are installed by
   Neovim itself; there's no framework runtime to load at startup. The loader
   (`lua/pack.lua`) collects every module's specs into **one** `vim.pack.add()`
   call.

3. **`data.lazy` — installed but not loaded.** These plugins carry no startup
   cost at all (no runtimepath entry, no `plugin/` sourcing) until something
   calls `require('pack').load{...}`:
   - `harpoon`, `git-worktree.nvim`, `neogit`+`diffview`, `img-clip.nvim`,
     the `nvim-dap` stack, and the alternate colorschemes.
   - Keeping `git-worktree` lazy also keeps **telescope** off the path until a
     worktree key is pressed elsewhere — a meaningful chunk of startup.

4. **`require('pack').defer(events, fn)` — deferred config.** The plugin's
   `config()` runs on the first matching event instead of at startup, then
   re-fires the event on already-open buffers so multi-file startups still get
   per-buffer setup:
   - **`InsertEnter`**: autopairs, supermaven
   - **`BufReadPre`/`BufNewFile`**: conform, gitsigns
   - **`BufReadPost`/`BufNewFile`**: indent-blankline, nvim-highlight-colors, nvim-ufo
   - **`FileType`**: render-markdown, lspconfig's document-highlight setup
   - **`LspAttach`**: fidget
   - **`UIEnter`** (after first frame): mini, noice, uv — plus inline-deferred
     claude, dressing, lualine, neoscroll
   - **`VimEnter`**: which-key, todo-comments, telescope

5. **Deferred work inside an eager `config()`.** `lspconfig` stays eager so
   `vim.lsp.enable(...)` attaches servers to the first file immediately — but the
   Mason installer machinery (`mason-tool-installer` / `mason-lspconfig`) is
   wrapped in `vim.schedule(...)`, so the package-registry load happens just
   *after* startup instead of during it.

6. **Disabled built-in runtime plugins** (`vim.g.loaded_*` at the top of
   `lua/pack.lua`): `gzip`, `matchit`, `tarPlugin`, `zipPlugin`, `2html`,
   `tutor`, `netrw`/`netrwPlugin` (Oil replaces netrw).

## What is intentionally kept eager (and why)

| Plugin / module | Why it stays eager |
|-----------------|--------------------|
| `colorscheme` (built-in `unokai` + highlights) | Must apply before the first paint |
| `transparent.nvim` | Must apply early or the background flashes |
| `snacks.nvim` | Paints the dashboard/splash; owns the shared terminal provider |
| `oil.nvim` | netrw replacement; must handle directory args at launch |
| `nvim-treesitter` | Highlighting on the first buffer (kept eager by choice) |
| `nvim-lspconfig` | LSP attaches to the first file immediately via `vim.lsp.enable` |
| `blink.cmp` | Provides LSP capabilities to lspconfig (`get_lsp_capabilities()`); can't defer without also deferring lspconfig |

The largest remaining eager cost is `blink.cmp` (~20 ms across its modules),
locked to eager lspconfig. Reclaiming it would mean deferring lspconfig itself
(`defer({ 'BufReadPre', 'BufNewFile' }, ...)`) and computing capabilities
lazily — a deliberate trade-off not taken here.

## Gotchas worth remembering

- A `defer()` trigger or a `data.lazy` plugin that's never loaded means the
  feature silently doesn't work — there is **no startup error**. After changing
  a trigger, actually press the key / open the filetype and confirm it loads
  (`:lua = vim.pack.get()` shows what's on the path).
- Laziness must be **unanimous**: if any module declares a shared plugin without
  `data.lazy`, the loader keeps it eager (one eager declaration wins). Check for
  a second module pulling in the same `src` if something you marked lazy loads
  early anyway.
- A plugin listed as a hard dependency of an eager plugin is effectively eager
  too. Keep heavy deps in their own `data.lazy` spec and `load{}` them on demand
  (this is why the Mason/DAP stacks are lazy, not dependencies).
- `scripts/smoke.sh` drives a real TUI over tmux/RPC to catch interactive-only
  breakage (dashboard render, FileType configs, UI plugins) that
  `nvim --headless` can't see — run it after loader changes.

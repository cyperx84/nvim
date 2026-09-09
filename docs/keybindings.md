# Keybindings Reference

Leader is `Space`. Which-key shows live hints — press `<leader>` and wait.

> This lists the bindings **this config defines**. For a plugin's *internal*
> keymaps (inside an Oil buffer, a Telescope picker, the Neogit status view),
> see that plugin's own help — they are not repeated here.

> **📖 Jump to**
> [Core Navigation](#core-navigation) • [File Management](#file-management) • [Git](#git) • [Search & LSP](#search--lsp) • [Text Editing](#text-editing) • [Buffers](#buffers-quickfix--diagnostics) • [AI](#ai-integrations) • [Plugin Specific](#plugin-specific) • [Quick Reference](#quick-reference)

**Sources:** `lua/keymaps.lua` (core), `lua/plugins/*.lua` (per plugin),
`after/plugin/herdr_nav.lua` (pane navigation).

## Leader groups (which-key)

Declared in `lua/plugins/which-key.lua` — only prefixes with live mappings behind
them are registered.

| Prefix | Group |
|--------|-------|
| `<leader>b` | [B]uffer |
| `<leader>c` | [C]ode / Claude Code |
| `<leader>d` | [D]iagnostic / debug |
| `<leader>g` | [G]it (`<leader>gw*` worktree) |
| `<leader>h` | [H]arpoon |
| `<leader>l` | [L]ocation list (note: `<leader>l` alone = format) |
| `<leader>o` | [O]bsidian |
| `<leader>O` | [O]penCode |
| `<leader>q` | [Q]uickfix |
| `<leader>s` | [S]earch (Telescope, LSP symbols) |
| `<leader>S` | [S]essions (mini.sessions) |
| `<leader>t` | [T]oggle |
| `<leader>u` | uv (Python) — registered by the plugin, not which-key |

---

## Core Navigation

### Window & pane navigation
*Source: `after/plugin/herdr_nav.lua`*

`<C-h/j/k/l>` move between Neovim splits **and herdr panes** with one chord: at
the edge of the last split the key is forwarded to herdr instead. Works in normal
and terminal mode, and overrides the `<C-w>` fallbacks in `keymaps.lua`. Lives in
`after/plugin/` so it loads last and wins over any plugin claiming the same keys.

| Keybind | Mode | Description |
|---------|------|-------------|
| `<C-h>` | Normal/Terminal | Navigate left (vim/herdr) |
| `<C-j>` | Normal/Terminal | Navigate down (vim/herdr) |
| `<C-k>` | Normal/Terminal | Navigate up (vim/herdr) |
| `<C-l>` | Normal/Terminal | Navigate right (vim/herdr) |

> Navigator.nvim was removed — `lua/plugins/tmux.lua` is now an empty stub. The
> herdr plugin keeps a tmux fallback, so the same keys still work under tmux.

### Terminal
*Source: `keymaps.lua`*

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<Esc><Esc>` | Terminal | `<C-\><C-n>` | Exit terminal mode |
| `<C-q>` | Terminal | `<C-\><C-n>` | Exit terminal mode |

### Basic operations
*Source: `keymaps.lua`*

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<Esc>` | Normal | `<cmd>nohlsearch<CR>` | Clear search highlighting |
| `<C-s>` | Normal | `:w<CR>` | Save file |
| `<C-q>` | Normal | `:q<CR>` | Quit current window |
| `jk` | Insert | `<Esc><Esc>` | Exit insert mode |
| `Q` | Normal | `<nop>` | Disabled (no Ex mode) |

### Scrolling
*Source: `lua/plugins/neoscroll.lua`*

Animated scrolling with **smart centering** — the cursor only re-centers (`zz`)
when mid-buffer, not at the top or bottom edge (neoscroll `post_hook`).

| Keybind | Action | Description |
|---------|--------|-------------|
| `<C-d>` | `neoscroll.ctrl_d` | Half page down (animated, smart center) |
| `<C-u>` | `neoscroll.ctrl_u` | Half page up (animated, smart center) |
| `<C-f>` | `neoscroll.ctrl_f` | Full page down (animated) |
| `<C-b>` | `neoscroll.ctrl_b` | Full page up (animated) |

---

## File Management

### Oil
*Source: `lua/plugins/oil.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<C-e>` | `require('oil').toggle_float()` | Toggle Oil float (cursor on current file) |

Inside an Oil buffer the config keeps Oil's own keymaps (`<CR>` open, `-` parent,
`g?` help, and the split/preview variants). Press `g?` in the buffer for the live
list rather than trusting a copy here.

---

## Git

### Neogit
*Source: `lua/plugins/neo-git.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>gg` | `:Neogit kind=floating<CR>` | Open Neogit (floating) |
| `<leader>gG` | `:Neogit kind=split<CR>` | Open Neogit (split) |
| `<leader>gb` | `:Neogit branch kind=auto<CR>` | Branch operations |
| `<leader>gB` | `:Neogit branch_config kind=auto<CR>` | Branch configuration |
| `<leader>gc` | `:Neogit commit kind=auto<CR>` | Commit operations |
| `<leader>gd` | `:Neogit diff kind=auto<CR>` | Diff operations |
| `<leader>gl` | `:Neogit log kind=auto<CR>` | Log operations |
| `<leader>gs` | `:Neogit stash kind=auto<CR>` | Stash operations |
| `<leader>gm` | `:Neogit merge kind=auto<CR>` | Merge operations |
| `<leader>gP` | `:Neogit pull<CR>` | Pull |
| `<leader>gp` | `:Neogit push<CR>` | Push |

### Git worktree
*Source: `lua/plugins/git-worktree.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>gwc` | `create_git_worktree()` | Create worktree |
| `<leader>gwl` | `git_worktrees()` | List / switch worktree (`<C-d>` to delete) |

### Gitsigns
*Source: `lua/plugins/gitsigns.lua`* — buffer-local, attaches on a tracked file.

| Keybind | Action | Description |
|---------|--------|-------------|
| `]c` | `nav_hunk 'next'` | Jump to next git change |
| `[c` | `nav_hunk 'prev'` | Jump to previous git change |
| `<leader>tb` | `toggle_current_line_blame` | Toggle git blame line |
| `<leader>tD` | `preview_hunk_inline` | Toggle inline deleted / preview hunk |

---

## Search & LSP

### Telescope
*Source: `lua/plugins/telescope.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>sh` | `builtin.help_tags` | Search help |
| `<leader>sk` | `builtin.keymaps` | Search keymaps |
| `<leader>sf` | `builtin.find_files` | Search files |
| `<leader>sF` | `find_files` (+ hidden/ignored) | Search all files |
| `<leader>ss` | `builtin.builtin` | Select Telescope picker |
| `<leader>sw` | `builtin.grep_string` | Search current word |
| `<leader>sg` | `builtin.live_grep` | Search by grep |
| `<leader>sd` | `builtin.diagnostics` | Search diagnostics |
| `<leader>sr` | `builtin.resume` | Resume last search |
| `<leader>s.` | `builtin.oldfiles` | Search recent files |
| `<leader><leader>` | `builtin.buffers` | Find existing buffers |
| `<leader>/` | `current_buffer_fuzzy_find` | Fuzzy search in current buffer |
| `<leader>s/` | `live_grep` (open files) | Live grep in open files only |
| `<leader>sn` | `find_files` (config dir) | Search Neovim config |

### LSP
*Source: `lua/plugins/lspconfig.lua`* — buffer-local, registered on `LspAttach`.

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `gd` | Normal | `lsp_definitions` | Goto definition |
| `gr` | Normal | `lsp_references` | Goto references |
| `gI` | Normal | `lsp_implementations` | Goto implementation |
| `gD` | Normal | `vim.lsp.buf.declaration` | Goto declaration |
| `<leader>D` | Normal | `lsp_type_definitions` | Type definition |
| `<leader>so` | Normal | `lsp_document_symbols` | Document symbols |
| `<leader>sW` | Normal | `lsp_dynamic_workspace_symbols` | Workspace symbols |
| `<leader>rn` | Normal | `vim.lsp.buf.rename` | Rename symbol |
| `<leader>ca` | Normal/Visual | `vim.lsp.buf.code_action` | Code action |
| `<leader>th` | Normal | toggle inlay hints | Toggle inlay hints (if supported) |

> **Overload:** `<leader>D` is globally **delete to void register** (see
> [Text Editing](#text-editing)) but is **buffer-locally remapped** to *LSP type
> definition* when a server attaches. Same for `<leader>ca`, which Claude Code
> also claims globally as *add file from tree*.

### Folds (nvim-ufo)
*Source: `lua/plugins/nvim-ufo.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `zR` | `openAllFolds` | Open all folds |
| `zM` | `closeAllFolds` | Close all folds |
| `zK` | `peekFoldedLinesUnderCursor` | Peek folded lines (falls back to LSP hover) |

---

## Text Editing

### Enhanced editing
*Source: `keymaps.lua`*

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `Y` | Normal | `y$` | Yank to end of line |
| `==` | Normal | `gg<S-v>G` | Select entire file |
| `J` | Normal | ``mzJ`z`` | Join lines, keep cursor position |
| `n` | Normal | `n` + smart `zzzv` | Next search (centers only mid-buffer) |
| `N` | Normal | `N` + smart `zzzv` | Previous search (centers only mid-buffer) |

### Clipboard
*Source: `keymaps.lua`*

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<leader>y` | Normal/Visual | `"+y` | Yank to system clipboard |
| `<leader>Y` | Normal | `"+Y` | Yank line to system clipboard |
| `<leader>D` | Normal/Visual | `"_d` | Delete to void register (see LSP overload) |
| `p` | Visual | `"_dP` | Paste without overwriting the register |

### Formatting (conform.nvim)
*Source: `lua/plugins/conform.lua`*

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<leader>l` | Normal/Visual | `conform.format` | Format file or range |

> **Conflict:** `<leader>l` (format) shadows the start of the `[L]ocation List`
> group (`<leader>ln` / `<leader>lp`). Pressing `<leader>l` formats immediately
> rather than waiting for the sub-key.

---

## Buffers, quickfix & diagnostics

### Buffers
*Sources: `keymaps.lua`, `lua/plugins/snacks.lua`*

| Keybind | Action | Description | Source |
|---------|--------|-------------|--------|
| `<leader>bq` | `<cmd>bd<CR>` | Close buffer | `keymaps.lua` |
| `<leader>bw` | `:bp\|bd #<CR>` | Close buffer, keep split | `keymaps.lua` |
| `<leader>bd` | `Snacks.bufdelete()` | Delete current buffer | `snacks.lua` |
| `<leader>ba` | `Snacks.bufdelete.all()` | Delete all buffers | `snacks.lua` |
| `<leader>bo` | `Snacks.bufdelete.other()` | Delete other buffers | `snacks.lua` |

### Quickfix & location list
*Source: `keymaps.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>qn` | `<cmd>cnext<CR>zz` | Next quickfix item |
| `<leader>qp` | `<cmd>cprev<CR>zz` | Previous quickfix item |
| `<leader>ln` | `<cmd>lnext<CR>zz` | Next location item |
| `<leader>lp` | `<cmd>lprev<CR>zz` | Previous location item |

### Diagnostics
*Source: `keymaps.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>dq` | `vim.diagnostic.setloclist` | Open diagnostic location list |

---

## AI Integrations

### Claude Code
*Source: `lua/plugins/claude.lua`* — `coder/claudecode.nvim`.

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<M-;>` | Normal | `<cmd>ClaudeCode<cr>` | Toggle Claude Code |
| `<M-;>` | Terminal | `toggle_claude_no_focus` | Toggle Claude (keep focus) |
| `<leader>cc` | Normal | `<cmd>ClaudeCode<cr>` | Toggle Claude Code |
| `<leader>cf` | Normal | `<cmd>ClaudeCodeFocus<cr>` | Focus Claude window |
| `<leader>cm` | Normal | `<cmd>ClaudeCodeSelectModel<cr>` | Select Claude model |
| `<leader>cr` | Normal | `<cmd>ClaudeCode --resume<cr>` | Resume session |
| `<leader>cC` | Normal | `<cmd>ClaudeCode --continue<cr>` | Continue session |
| `<leader>cb` | Normal | `add_current_buffer` | Add current buffer |
| `<leader>cB` | Normal | `send_all_buffers` | Add all buffers |
| `<leader>cs` | Visual | `<cmd>ClaudeCodeSend<cr>` | Send selection |
| `<leader>cS` | Normal | `<cmd>ClaudeCodeSend<cr>` | Send current line |
| `<leader>ca` | Normal | `<cmd>ClaudeCodeTreeAdd<cr>` | Add file from tree (Oil / mini.files) |
| `<leader>c?` | Normal | `<cmd>help claudecode<cr>` | Claude Code help |
| `<leader>cq` | Normal | `<cmd>ClaudeCodeClose<cr>` | Quit Claude Code |

### OpenCode
*Source: `lua/plugins/opencode.lua`* — `NickvanDyke/opencode.nvim`. The plugin
defines more `<leader>O*` bindings than the headline ones below; press
`<leader>O` and let which-key list them.

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<M-'>` | Normal/Terminal | `require('opencode').toggle()` | Toggle OpenCode |
| `<leader>Oa` | Normal/Visual | `opencode.ask('@this: ')` | Ask OpenCode about context |
| `<leader>Ox` | Normal/Visual | `opencode.select()` | Select / execute action |
| `go` | Normal/Visual | `opencode.operator('@this ')` | Add range to OpenCode (operator) |
| `goo` | Normal | `opencode.operator` (line) | Add current line to OpenCode |

### Supermaven
*Source: `lua/plugins/super-maven.lua`* — inline completion.

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<C-y>` | Insert | `accept_suggestion` | Accept suggestion |
| `<C-]>` | Insert | `clear_suggestion` | Clear suggestion |
| `<C-j>` | Insert | `accept_word` | Accept next word |

---

## Plugin Specific

### Harpoon
*Source: `lua/plugins/harpoon.lua`* — harpoon2, marks are per project.

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>ha` | `list():add()` | Mark current file |
| `<leader>he` | `ui:toggle_quick_menu` | Toggle Harpoon menu |
| `<leader>hj` `<leader>hk` `<leader>hl` | `list():select(1..3)` | Jump to file 1–3 |
| `<leader>hu` `<leader>hi` `<leader>ho` | `list():select(4..6)` | Jump to file 4–6 |
| `<leader>h7` `<leader>h8` `<leader>h9` | `list():select(7..9)` | Jump to file 7–9 |

Moved off `<M-...>` 2026-08: herdr claims `alt+1..6` for tabs and
`alt+j/k/l/u/i/o/7/8/9` for workspaces, so those chords never reach Neovim. The
letters are unchanged, only the prefix moved.

### Obsidian
*Source: `lua/plugins/obsidian.lua`* — modern `:Obsidian <subcmd>` syntax,
buffer-local inside the vault.

| Keybind | Mode | Action | Description |
|---------|------|--------|-------------|
| `<leader>oc` | Normal | `util.toggle_checkbox()` | Toggle checkbox |
| `<leader>oc` | Visual | toggle range | Toggle checkboxes in selection |
| `<leader>on` | Normal | `:Obsidian new<CR>` | New note |
| `<leader>oo` | Normal | `:Obsidian open<CR>` | Open in Obsidian app |
| `<leader>of` | Normal | `:Obsidian quick_switch<CR>` | Find / quick switch note |
| `<leader>or` | Normal | rename | Rename note |
| `<leader>os` | Normal | `:Obsidian search<CR>` | Search vault |
| `<leader>ob` | Normal | backlinks | Show backlinks |
| `<leader>ol` | Normal | `:Obsidian links<CR>` | Show links |
| `<leader>ot` | Normal | `:Obsidian tags<CR>` | Show tags |
| `<leader>oF` | Normal | `:Obsidian follow_link<CR>` | Follow link |
| `<leader>ox` | Normal | `:Obsidian toc<CR>` | Table of contents |
| `<leader>od` | Normal | `:Obsidian today<CR>` | Today's daily note |
| `<leader>oy` | Normal | `:Obsidian yesterday<CR>` | Yesterday's note |
| `<leader>om` | Normal | `:Obsidian tomorrow<CR>` | Tomorrow's note |
| `<leader>ow` | Normal | `:Obsidian workspace<CR>` | Switch workspace |
| `<leader>oi` | Normal | `:Obsidian paste_img<CR>` | Paste image |
| `<leader>oe` | Visual | `:Obsidian extract_note<CR>` | Extract note |
| `<leader>oL` | Visual | `:Obsidian link<CR>` | Link selection |
| `<leader>oln` | Visual | `:Obsidian link_new<CR>` | Link to new note |
| `<leader>ch` | Normal | `util.toggle_checkbox()` | Toggle checkbox (alias) |
| `gf` / `<CR>` | Normal | follow link | Follow link under cursor |

### Sessions (mini.sessions)
*Source: `lua/plugins/mini.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>Ss` | write (prompt name) | Save session |
| `<leader>Sw` | write current | Save current session |
| `<leader>Sh` | dashboard | Close all + show dashboard |
| `<leader>Sn` | read `notes` | Open Notes session |
| `<leader>Sd` | read `dotfiles` | Open Dotfiles session |
| `<leader>Sc` | read `code` | Open Code session |
| `<leader>Sl` | select read | Load session (picker) |
| `<leader>Sr` | read (prompt name) | Restore session by name |
| `<leader>Sx` | select delete | Delete session (picker) |

### uv (Python)
*Source: `lua/plugins/uv.lua`* — the plugin registers its own keymaps under the
`<leader>u` prefix.

| Keybind | Description |
|---------|-------------|
| `<leader>u` | uv commands menu (prefix) |
| `<leader>ur` | Run current file |
| `<leader>us` | Run selection |
| `<leader>uf` | Run function |
| `<leader>ue` | Environment management |
| `<leader>ui` | Init uv project |
| `<leader>ua` / `<leader>ud` | Add / remove package |
| `<leader>uc` / `<leader>uC` | Sync / sync all |

### Debugging (nvim-dap)
*Source: `lua/plugins/debug.lua`*

| Keybind | Action | Description |
|---------|--------|-------------|
| `<leader>ds` | `dap.continue()` | Start / continue |
| `<leader>di` | `dap.step_into()` | Step into |
| `<leader>do` | `dap.step_over()` | Step over |
| `<leader>du` | `dap.step_out()` | Step out |
| `<leader>b` | `dap.toggle_breakpoint()` | Toggle breakpoint |
| `<leader>B` | `dap.set_breakpoint(...)` | Conditional breakpoint |
| `<leader>dd` | `dapui.toggle()` | Toggle DAP UI / last result |

### UI toggles & misc
*Sources: `lua/plugins/{transparent,mini,snacks,image}.lua`*

| Keybind | Action | Description | Source |
|---------|--------|-------------|--------|
| `<leader>tt` | transparent toggle | Toggle transparency | `transparent.lua` |
| `<leader>td` | `mini.diff` toggle overlay | Toggle MiniDiff overlay | `mini.lua` |
| `<leader>tz` | `Snacks.zen()` | Toggle Zen mode | `snacks.lua` |
| `<leader>tT` | `Snacks.terminal.toggle()` | Toggle floating terminal | `snacks.lua` |
| `<leader>z` | dismiss notifications | Dismiss Snacks notifications | `snacks.lua` |
| `<leader>pi` | `<cmd>PasteImage<CR>` | Paste image | `image.lua` |

---

## Quick Reference

```
Files:        <C-e> (Oil float)
Search:       <leader>sf (files), <leader>sg (grep), <leader><leader> (buffers)
Git:          <leader>gg (Neogit), <leader>gp (push), <leader>gc (commit)
Navigation:   <C-hjkl> (splits + herdr panes), jk (exit insert)
Files (nav):  <leader>hj/k/l/u/i/o (Harpoon 1-6), <leader>ha (mark), <leader>he (menu)
Editing:      <leader>y (system yank), Y (yank line), <leader>l (format)
AI:           <M-;> (Claude Code), <M-'> (OpenCode), <C-y> (Supermaven accept)
```

### Alt row belongs to herdr

Bare `alt+…` chords are claimed by herdr before Neovim ever sees them:
`alt+1..6` focus tabs, `alt+j/k/l/u/i/o/7/8/9` focus workspaces, plus
`alt+s/v/c/x/w/r/q/n/b/g/e/m` for pane and workspace management. Config lives in
`~/dotfiles/mac/herdr/.config/herdr/config.toml`; the cross-tool arbitration
table is [`docs/KEYBINDS.md`](https://github.com/cyperx84/dotfiles/blob/main/docs/KEYBINDS.md)
in the dotfiles repo.

`<M-;>` and `<M-'>` still reach Neovim — herdr does not bind them.

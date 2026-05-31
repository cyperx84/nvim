# Keybindings Reference

Leader is `Space`. Which-key shows live hints — press `<leader>` and wait.

> This lists the custom and plugin bindings defined in this config. For a
> plugin's *internal* keymaps (e.g. inside Oil or the Telescope picker), see
> that plugin's own help.

## Leader groups (which-key)

| Prefix | Group |
|--------|-------|
| `<leader>c` | [C]ode |
| `<leader>d` | [D]iagnostic |
| `<leader>r` | [R]ename |
| `<leader>s` | [S]earch (Telescope) |
| `<leader>w` | [W]orkspace |
| `<leader>t` | [T]oggle |
| `<leader>h` | Git [H]unk |
| `<leader>g` | [G]it |
| `<leader>o` | [O]bsidian |
| `<leader>b` | [B]uffer |
| `<leader>q` | [Q]uickfix |
| `<leader>l` | [L]ocation list |

## Global editing & motion (`lua/keymaps.lua`)

| Key | Mode | Action |
|-----|------|--------|
| `<Esc>` | n | Clear search highlight |
| `jk` | i | Exit insert mode |
| `Y` | n | Yank to end of line (like `C`/`D`) |
| `==` | n | Select entire file |
| `J` | n | Join line, keep cursor centered |
| `n` / `N` | n | Next/prev search, smart-centered |
| `p` | v | Paste without clobbering the register |
| `<leader>y` / `<leader>Y` | n/v | Yank to system clipboard |
| `<leader>D` | n/v | Delete to the void register (keeps clipboard) |
| `Q` | n | Disabled (no-op) |
| `<C-s>` | n | Save file |
| `<C-q>` | n | Quit buffer |
| `<C-d>` / `<C-u>` | n | Half-page scroll, centered (neoscroll) |

## Windows & terminal

| Key | Mode | Action |
|-----|------|--------|
| `<C-h/j/k/l>` | n, t | Move between splits / tmux panes (Navigator) |
| `<Esc><Esc>` | t | Exit terminal mode |
| `<C-q>` | t | Exit terminal mode |

## Buffers / quickfix / location list

| Key | Action |
|-----|--------|
| `<leader>bq` | Close buffer |
| `<leader>bw` | Close buffer, keep split |
| `<leader>qn` / `<leader>qp` | Next/prev quickfix item |
| `<leader>ln` / `<leader>lp` | Next/prev location-list item |
| `<leader>dq` | Diagnostics → location list |

## Harpoon (file marks) — Alt keys

Migrated to **harpoon2**. Marks are per project.

| Key | Action |
|-----|--------|
| `<M-a>` | Mark current file |
| `<M-e>` | Toggle quick menu |
| `<M-j>` `<M-k>` `<M-l>` | Jump to file 1 / 2 / 3 |
| `<M-u>` `<M-i>` `<M-o>` | Jump to file 4 / 5 / 6 |
| `<M-7>` `<M-8>` `<M-9>` | Jump to file 7 / 8 / 9 |

## File navigation

| Key | Action |
|-----|--------|
| `-` | Open Yazi file manager |
| `<C-e>` | Toggle Oil explorer |
| `<leader>sf` | Find files (Telescope) |
| `<leader>sg` | Live grep (Telescope) |

## LSP (active when a server attaches)

| Key | Action |
|-----|--------|
| `gd` / `gr` / `gI` | Goto definition / references / implementation |
| `gD` | Goto declaration |
| `<leader>D` | Type definition |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action (n, x) |
| `<leader>so` / `<leader>sW` | Document / workspace symbols |
| `<leader>th` | Toggle inlay hints |

## Git

| Key | Action |
|-----|--------|
| `<leader>gg` | Open Neogit |
| `]c` / `[c` | Next / prev hunk (gitsigns) |
| `<leader>tb` | Toggle line blame |
| `<leader>gwl` | List git worktrees (`<C-d>` to delete) |
| `<leader>gwc` | Create git worktree |

## AI assistants

| Key | Mode | Action |
|-----|------|--------|
| `<M-;>` | n | Toggle Claude Code |
| `<M-c>` | n | CodeCompanion chat |
| `<M-'>` | n, t | Toggle OpenCode |
| `<leader>Oa` | n, x | OpenCode: ask about selection/line |
| `<leader>Ox` | n, x | OpenCode: pick an action |
| `go` / `goo` | n, x / n | Add range / line to OpenCode |

## Obsidian (`<leader>o…`)

| Key | Action |
|-----|--------|
| `<leader>os` | Search vault |
| `<leader>ob` | Backlinks |
| `<leader>ol` | Links in note |
| `<leader>ot` | Tags |
| `<leader>oF` | Follow link |

## Toggles (`<leader>t…`)

| Key | Action |
|-----|--------|
| `<leader>tm` | Toggle Markview |
| `<leader>tb` | Toggle git line blame |
| `<leader>tD` | Toggle inline deleted (gitsigns) |
| `<leader>th` | Toggle LSP inlay hints |

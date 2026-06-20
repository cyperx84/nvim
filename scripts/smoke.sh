#!/usr/bin/env bash
# Headless smoke test for the vim.pack config.
#
# Drives a REAL nvim TUI inside a detached tmux session over RPC, so it
# catches interactive-only failures (dashboard render, window resize,
# FileType configs, UI plugins) that `nvim --headless` alone cannot see.
#
# Usage:
#   scripts/smoke.sh                 # full sweep
#   scripts/smoke.sh --with-claude   # also toggles the ClaudeCode terminal
#                                    # (spawns a real `claude` process briefly)
#
# Error detection: noice reroutes :messages (ext_messages), so plain
# `execute("messages")` is blind once noice is up. We check three signals
# after every step: noice's error history, error text rendered on screen,
# and stderr from the headless boot.
set -u

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)" || exit 1

WITH_CLAUDE=0
[ "${1:-}" = "--with-claude" ] && WITH_CLAUDE=1

FAIL=0
pass() { printf 'ok:   %s\n' "$*"; }
fail() { FAIL=1; printf 'FAIL: %s\n' "$*"; }

# ---------------------------------------------------------------- 1. syntax
syntax_bad=0
for f in init.lua lua/pack.lua lua/plugins/*.lua; do
  err=$(nvim --clean --headless +"lua local _,e=loadfile('$f'); io.write(e or '')" +q 2>&1)
  if [ -n "$err" ]; then
    fail "syntax: $f: $err"
    syntax_bad=1
  fi
done
[ "$syntax_bad" = 0 ] && pass "syntax sweep (init.lua, pack.lua, $(/bin/ls lua/plugins/*.lua | wc -l | tr -d ' ') modules)"

# --------------------------------------------------------- 2. headless boot
# Drop benign vim.pack progress (install/update chatter on first boot) and
# nvim-treesitter notices, but KEEP vim.pack lines that look like errors so a
# failed clone/fetch is not silently swallowed.
boot_out=$(nvim --headless +'qa!' 2>&1 \
  | grep -v '^\[nvim-treesitter' \
  | awk 'tolower($0) ~ /error|fail|conflict|cannot|unable|not found/ || $0 !~ /^vim\.pack:/' \
  || true)
if [ -n "$(printf %s "$boot_out" | tr -d '[:space:]')" ]; then
  fail "headless boot produced output: $boot_out"
else
  pass "headless boot"
fi

# ------------------------------------------------------------- 3. real TUI
SESSION="nvim-smoke-$$"
SOCK="/tmp/$SESSION.sock"
TESTMD="/tmp/$SESSION.md"
TESTLUA="/tmp/$SESSION.lua"
printf '# smoke\n\n- [ ] item\n' > "$TESTMD"
printf 'local x = 1\nprint(x)\n' > "$TESTLUA"

cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null
  rm -f "$SOCK" "$TESTMD" "$TESTLUA"
}
trap cleanup EXIT

if ! tmux new-session -d -s "$SESSION" -x 200 -y 50 "nvim --listen $SOCK"; then
  fail "could not start tmux session"
  exit 1
fi

rpc() { nvim --server "$SOCK" --remote-expr "$1" 2>&1; }

up=""
for _ in $(seq 1 60); do
  if rpc '1' >/dev/null 2>&1; then up=1; break; fi
  sleep 0.5
done
if [ -z "$up" ]; then
  fail "nvim RPC never came up; pane:"
  tmux capture-pane -t "$SESSION" -p | tail -10
  exit 1
fi
sleep 3 # let UIEnter/VimEnter configs settle

# Errors recorded by noice (or :messages before noice attaches).
NOICE_ERRS='luaeval("(function() local ok, n = pcall(function() return #require(\"noice.message.manager\").get({ error = true }, { history = true }) end) if ok then return n end return -1 end)()")'
err_count() {
  local n
  n=$(rpc "$NOICE_ERRS")
  if [ "$n" = "-1" ]; then
    # noice not up yet: fall back to :messages (works without ext_messages)
    if [ -n "$(rpc 'execute("messages")' | tr -d '[:space:]')" ]; then echo 999; else echo 0; fi
  else
    echo "$n"
  fi
}

BASE_ERRS=$(err_count)

step() { # $1 = label; checks error delta + visible error text
  local n pane
  n=$(err_count)
  pane=$(tmux capture-pane -t "$SESSION" -p)
  if [ "$n" -gt "$BASE_ERRS" ]; then
    fail "$1: noice recorded $((n - BASE_ERRS)) new error(s); recent:"
    rpc 'luaeval("(function() local ok, m = pcall(function() local t = require(\"noice.message.manager\").get({ error = true }, { history = true, sort = true }) local last = t[#t] return last and table.concat(vim.tbl_map(function(l) return l:content() end, last._lines or {}), \" | \") or \"?\" end) return ok and m or \"<unreadable>\" end)()")'
    echo
    BASE_ERRS=$n
  elif printf '%s' "$pane" | grep -q 'Error detected\|Error executing\|Error in .*Autocommands\|stack traceback'; then
    fail "$1: error text rendered on screen"
  else
    pass "$1"
  fi
}

step "TUI startup (dashboard + VimEnter configs)"

tmux resize-window -t "$SESSION" -x 120 -y 30; sleep 1
tmux resize-window -t "$SESSION" -x 80 -y 24; sleep 1
tmux resize-window -t "$SESSION" -x 200 -y 50; sleep 1
step "window resize cycles (dashboard re-render)"

rpc "execute(\"edit $TESTMD\")" >/dev/null; sleep 2
step "markdown buffer (obsidian + render-markdown FileType)"

rpc "execute(\"edit $TESTLUA\")" >/dev/null; sleep 3
step "lua buffer (treesitter + LSP attach)"

lsp=$(rpc 'luaeval("table.concat(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients()), \",\")")')
case "$lsp" in
  *lua_ls*) pass "lua_ls attached ($lsp)" ;;
  *) fail "lua_ls not attached (clients: ${lsp:-none})" ;;
esac

rpc 'execute("doautocmd InsertEnter")' >/dev/null; sleep 1
step "InsertEnter configs (autopairs, supermaven)"

rpc 'execute("lua require(\"oil\").toggle_float()")' >/dev/null; sleep 1
step "oil float open"
rpc 'execute("lua require(\"oil\").toggle_float()")' >/dev/null; sleep 1

# ---------------------------------------------------- lazy-load keymap targets
# Plugins behind data.lazy never load at boot, so a wrong name in a module's
# require('pack').load{...} list (or a setup error) escapes every check above —
# the user only finds out on the keypress days later. Exercise each lazy module's
# real load list + require its public modules here, plus the commands the
# keymaps invoke directly, so a broken name fails CI instead of in daily use.
LAZY_CHECK="luaeval(\"(function() local pack=require('pack') local groups={ {{'harpoon'},{'harpoon'}}, {{'git-worktree.nvim'},{'git-worktree'}}, {{'neogit','diffview.nvim'},{'diffview'}}, {{'nvim-nio','nvim-dap','nvim-dap-ui','mason-nvim-dap.nvim','nvim-dap-go'},{'nio','dap','dapui','mason-nvim-dap','dap-go'}}, {{'img-clip.nvim'},{'img-clip'}} } local errs={} for _,g in ipairs(groups) do local ok,e=pcall(pack.load,g[1]) if not ok then errs[#errs+1]='load '..table.concat(g[1],',')..': '..tostring(e) end for _,m in ipairs(g[2]) do local rok,rerr=pcall(require,m) if not rok then errs[#errs+1]='require '..m..': '..tostring(rerr) end end end if vim.fn.exists(':Neogit')~=2 then errs[#errs+1]='no :Neogit after load' end if vim.fn.exists(':PasteImage')~=2 then errs[#errs+1]='no :PasteImage after load' end return #errs==0 and 'ok' or table.concat(errs,' | ') end)()\")"
lazy_out=$(rpc "$LAZY_CHECK")
if [ "$lazy_out" = "ok" ]; then
  pass "lazy-load targets (harpoon, git-worktree, neogit/diffview, dap stack, img-clip)"
else
  fail "lazy-load: $lazy_out"
fi

# Auto-coverage: every data.lazy plugin (from pack.M.lazy) must packadd cleanly.
# This syncs itself — a new lazy plugin is checked here without editing the test,
# even if the curated require/command list above isn't updated for it.
ALL_LAZY="luaeval(\"(function() local pack=require('pack') local errs={} for _,n in ipairs(pack.lazy or {}) do local ok,e=pcall(pack.load,{n}) if not ok then errs[#errs+1]=n..': '..tostring(e) end end return #errs==0 and 'ok' or table.concat(errs,' | ') end)()\")"
all_lazy_out=$(rpc "$ALL_LAZY")
if [ "$all_lazy_out" = "ok" ]; then
  pass "all data.lazy specs packadd cleanly ($(rpc 'luaeval("#(require(\"pack\").lazy or {})")') plugins)"
else
  fail "lazy spec packadd: $all_lazy_out"
fi

if [ "$WITH_CLAUDE" = 1 ]; then
  rpc 'execute("ClaudeCode")' >/dev/null; sleep 4
  step "ClaudeCode terminal toggle open"
  rpc 'execute("ClaudeCode")' >/dev/null; sleep 1
  step "ClaudeCode terminal toggle close"
fi

echo
if [ "$FAIL" = 0 ]; then
  echo "smoke: ALL CHECKS PASSED"
else
  echo "smoke: FAILURES (see above)"
fi
exit "$FAIL"

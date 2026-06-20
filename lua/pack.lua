-- Native vim.pack plugin loading (replaces lazy.nvim).
--
-- Each lua/plugins/*.lua module declares:
--   M.specs    list of vim.pack.Spec tables ({ src = ..., version = ..., data = { ... } })
--   M.config() runtime setup (setup calls, keymaps, deferral autocmds)
-- All specs are collected into one vim.pack.add() call (deduped by plugin
-- name), then each module's config runs in the order listed below.
--
-- spec.data is our own convention on top of vim.pack:
--   data.build  build hook, run by the PackChanged autocmd below:
--                 ':Cmd' -> ex-command (plugin is packadd'ed first)
--                 'make' -> shell command run inside the plugin dir
--                 func   -> called with the PackChanged event
--   data.lazy   true to install the plugin WITHOUT loading it at startup
--               (no runtimepath entry, no plugin/ sourcing). Modules load it
--               on demand with require('pack').load { 'name', ... }.

local M = {}

-- Disable rarely-used built-in runtime plugins (oil/yazi replace netrw).
vim.g.loaded_gzip = 1
vim.g.loaded_matchit = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('pack-build-hooks', { clear = true }),
  callback = function(ev)
    local build = vim.tbl_get(ev.data.spec, 'data', 'build')
    if not build or ev.data.kind == 'delete' then
      return
    end
    local is_shell = type(build) == 'string' and build:sub(1, 1) ~= ':'
    if not is_shell and not ev.data.active then
      vim.cmd.packadd(ev.data.spec.name)
    end
    if type(build) == 'function' then
      build(ev)
    elseif is_shell then
      local res = vim.system({ 'sh', '-c', build }, { cwd = ev.data.path }):wait()
      if res.code ~= 0 then
        vim.notify(('pack: build failed for %s:\n%s'):format(ev.data.spec.name, res.stderr or ''), vim.log.levels.ERROR)
      end
    else
      vim.cmd(build:sub(2))
    end
  end,
})

-- Load lazy-installed plugins (spec.data.lazy) on demand. Safe to call with
-- already-loaded names; each plugin is packadd'ed (runtimepath + plugin/
-- sourcing) at most once.
local demand_loaded = {}
function M.load(names)
  for _, name in ipairs(names) do
    if not demand_loaded[name] then
      demand_loaded[name] = true
      vim.cmd.packadd(name)
    end
  end
end

-- Defer `fn` until the first time any of `events` fires (once), replacing the
-- per-module `nvim_create_autocmd(..., { once = true })` boilerplate that was
-- copy-pasted across a dozen modules. For buffer-scoped events the triggering
-- event is re-fired after `fn` runs, so a plugin whose setup() registers
-- per-buffer autocmds still processes files that were already open when it
-- loaded (exactly what lazy.nvim did when it loaded a plugin on an event).
-- opts.pattern restricts the autocmd (e.g. a FileType gate).
local buf_events = {
  BufRead = true,
  BufReadPre = true,
  BufReadPost = true,
  BufNewFile = true,
  FileType = true,
}

-- Does `buf` satisfy autocmd `pattern` for `event`? FileType patterns match
-- the buffer's filetype; read/new events match its name. `pattern` may be a
-- string or a list (as nvim_create_autocmd accepts); nil means "any buffer"
-- (for FileType, any buffer that has a filetype set).
local function buf_matches(buf, event, pattern)
  if event == 'FileType' then
    local ft = vim.bo[buf].filetype
    if ft == '' then
      return false
    end
    if pattern == nil then
      return true
    end
    for _, p in ipairs(type(pattern) == 'table' and pattern or { pattern }) do
      if ft == p then
        return true
      end
    end
    return false
  end
  if pattern == nil then
    return true
  end
  local name = vim.api.nvim_buf_get_name(buf)
  for _, p in ipairs(type(pattern) == 'table' and pattern or { pattern }) do
    if vim.fn.match(name, vim.fn.glob2regpat(p)) ~= -1 then
      return true
    end
  end
  return false
end

-- Re-fire `event` on `buf`. FileType must be re-fired in the buffer's own
-- context with its filetype as the pattern: a bare `buffer=` re-fire bypasses
-- filetype routing and runs handlers for the wrong filetype. Other buffer
-- events route correctly via `buffer=`.
local function refire(event, buf)
  if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)) then
    return
  end
  if event == 'FileType' then
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_exec_autocmds('FileType', { pattern = vim.bo[buf].filetype, modeline = false })
    end)
  else
    vim.api.nvim_exec_autocmds(event, { buffer = buf, modeline = false })
  end
end

local refired = {} -- collapses duplicate re-fires of the same event+buffer
function M.defer(events, fn, opts)
  opts = opts or {}
  vim.api.nvim_create_autocmd(events, {
    once = true,
    pattern = opts.pattern,
    callback = function(ev)
      fn(ev)
      if not buf_events[ev.event] then
        return
      end
      -- Re-fire the trigger on EVERY buffer already open when we loaded, not
      -- just ev.buf, so multi-file / session-restore startups (`nvim a b`,
      -- :argadd, a restored session) get each matching buffer processed by the
      -- handlers fn() just registered. Idempotent FileType/BufRead handlers
      -- tolerate the re-fire; opts.pattern keeps the blast radius to buffers
      -- this plugin actually targets.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and buf_matches(buf, ev.event, opts.pattern) then
          local k = ev.event .. ':' .. buf
          if not refired[k] then
            refired[k] = true
            vim.schedule(function()
              refired[k] = nil
              refire(ev.event, buf)
            end)
          end
        end
      end
    end,
  })
end

-- Modules are auto-discovered from lua/plugins/, so dropping in a new file is
-- enough — no second place to register it, no silent "forgot the list" gap.
-- Only the few with real config-order constraints are pinned; everything else
-- runs alphabetically between them:
--   colorscheme first — set the theme/highlights before anything renders
--   snacks early       — owns the dashboard splash + terminal provider that
--                        claude/opencode reuse
--   debug last         — its DAP setup needs mason.setup (lspconfig, which sorts
--                        earlier alphabetically) to have run first
--   sleuth last        — should observe options set by everything else
-- (cmp-before-lspconfig, the other constraint, holds for free: both are in the
-- alphabetical middle and 'cmp' < 'lspconfig'.)
local order_first = { 'colorscheme', 'snacks' }
local order_last = { 'debug', 'sleuth' }

local function discover_modules()
  local pinned = {}
  for _, n in ipairs(order_first) do
    pinned[n] = true
  end
  for _, n in ipairs(order_last) do
    pinned[n] = true
  end

  local middle, seen = {}, {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file('lua/plugins/*.lua', true)) do
    local mod = path:match '([^/\\]+)%.lua$'
    if mod and mod ~= 'init' and not pinned[mod] and not seen[mod] then
      seen[mod] = true
      middle[#middle + 1] = mod
    end
  end
  table.sort(middle)

  local modules = {}
  vim.list_extend(modules, order_first)
  vim.list_extend(modules, middle)
  vim.list_extend(modules, order_last)
  return modules
end

local modules = discover_modules()

local specs, seen, mods = {}, {}, {}
for _, name in ipairs(modules) do
  local ok, mod = pcall(require, 'plugins.' .. name)
  if not ok then
    vim.notify(('pack: failed to load module plugins.%s\n%s'):format(name, mod), vim.log.levels.ERROR)
  else
    mods[#mods + 1] = { name = name, config = mod.config }
    for _, spec in ipairs(mod.specs or {}) do
      if type(spec) == 'string' then
        spec = { src = spec }
      end
      if type(spec) ~= 'table' or type(spec.src) ~= 'string' then
        -- A malformed spec must not abort collection for every later module.
        vim.notify(('pack: plugins.%s has a spec with no src; skipping it'):format(name), vim.log.levels.WARN)
      else
        local base = (spec.src:match '([^/]+)$' or spec.src):gsub('%.git$', '')
        local key = spec.name or base
        local kept = seen[key]
        if not kept then
          seen[key] = spec
          specs[#specs + 1] = spec
        else
          -- Same plugin declared by several modules: keep one spec but don't
          -- lose a pin or build hook that only the duplicate carries. Laziness
          -- must be unanimous — one eager declaration makes the plugin eager.
          -- A divergent pin can't be silently dropped on module-list order:
          -- surface the conflict so the resolution is a deliberate choice.
          if kept.version and spec.version and not vim.deep_equal(kept.version, spec.version) then
            vim.notify(('pack: %s declared with conflicting version pins; keeping the first-declared'):format(key), vim.log.levels.WARN)
          end
          kept.version = kept.version or spec.version
          local kept_lazy = kept.data and kept.data.lazy or false
          local spec_lazy = spec.data and spec.data.lazy or false
          if spec.data then
            kept.data = kept.data or {}
            kept.data.build = kept.data.build or spec.data.build
          end
          if kept.data then
            kept.data.lazy = (kept_lazy and spec_lazy) or nil
          end
        end
      end
    end
  end
end

local eager_specs, lazy_specs = {}, {}
-- Names of every lazy plugin, exposed for the smoke test to auto-cover: it
-- packadds each and confirms it loads, so a new data.lazy plugin gets baseline
-- coverage without anyone updating the test by hand.
M.lazy = {}
for _, spec in ipairs(specs) do
  if spec.data and spec.data.lazy then
    lazy_specs[#lazy_specs + 1] = spec
    M.lazy[#M.lazy + 1] = (spec.src:match '([^/]+)$' or spec.src):gsub('%.git$', '')
  else
    eager_specs[#eager_specs + 1] = spec
  end
end

-- A malformed spec or fatal install error must not take down the whole
-- config: keep the per-module pcall philosophy here too, so the config loop
-- below still runs (colorscheme, keymaps, LSP, …) even if a plugin fails.
local ok_add, add_err = pcall(vim.pack.add, eager_specs, { confirm = false })
if not ok_add then
  vim.notify('pack: vim.pack.add failed for eager specs\n' .. tostring(add_err), vim.log.levels.ERROR)
end
if #lazy_specs > 0 then
  -- Installed and update-managed like everything else, but a no-op load
  -- keeps them off the runtimepath until require('pack').load.
  local ok_lazy, lazy_err = pcall(vim.pack.add, lazy_specs, { confirm = false, load = function() end })
  if not ok_lazy then
    vim.notify('pack: vim.pack.add failed for lazy specs\n' .. tostring(lazy_err), vim.log.levels.ERROR)
  end
end

-- Make the loader resolvable from module config() bodies (which run just
-- below and call require('pack').defer/load) without recursively re-requiring
-- this file mid-load.
package.loaded['pack'] = M

for _, m in ipairs(mods) do
  if m.config then
    local ok, err = pcall(m.config)
    if not ok then
      vim.notify(('pack: config failed for plugins.%s\n%s'):format(m.name, err), vim.log.levels.ERROR)
    end
  end
end

return M
-- vim: ts=2 sts=2 sw=2 et

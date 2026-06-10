-- Native vim.pack plugin loading (replaces lazy.nvim).
--
-- Each lua/plugins/*.lua module declares:
--   M.specs    list of vim.pack.Spec tables ({ src = ..., version = ..., data = { build = ... } })
--   M.config() runtime setup (setup calls, keymaps, deferral autocmds)
-- All specs are collected into a single vim.pack.add() call (deduped by
-- plugin name), then each module's config runs in the order listed below.

-- Disable rarely-used built-in runtime plugins (oil/yazi replace netrw).
vim.g.loaded_gzip = 1
vim.g.loaded_matchit = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- Build hooks declared as spec.data.build:
--   ':Cmd' -> ex-command, run after install/update (plugin is packadd'ed first)
--   'make' -> shell command run inside the plugin dir
--   func   -> called with the PackChanged event (plugin is packadd'ed first)
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

-- Config order: colorscheme first (was priority=1000 under lazy), snacks
-- early (dashboard splash), the rest in lazy's old import order
-- (alphabetical), with two constraint-driven moves: lspconfig before debug
-- (mason.setup must precede mason-nvim-dap.setup now that debug is eager),
-- and sleuth last.
local modules = {
  'colorscheme',
  'snacks',
  'autopairs',
  'claude',
  'cmp',
  'conform',
  'lspconfig',
  'debug',
  'dressing',
  'ghostty',
  'git-worktree',
  'gitsigns',
  'harpoon',
  'highlight-colors',
  'image',
  'indent_line',
  'lualine',
  'mini',
  'neo-git',
  'neoscroll',
  'noice',
  'notify',
  'nvim-ufo',
  'obsidian',
  'oil',
  'opencode',
  'render-markdown',
  'super-maven',
  'telescope',
  'tmux',
  'todo-comments',
  'transparent',
  'treesitter',
  'uv',
  'web-dev-icons',
  'which-key',
  'sleuth',
}

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
      local base = (spec.src:match '([^/]+)$' or spec.src):gsub('%.git$', '')
      local key = spec.name or base
      local kept = seen[key]
      if not kept then
        seen[key] = spec
        specs[#specs + 1] = spec
      else
        -- Same plugin declared by several modules: keep one spec but don't
        -- lose a pin or build hook that only the duplicate carries.
        kept.version = kept.version or spec.version
        kept.data = kept.data or spec.data
      end
    end
  end
end

vim.pack.add(specs, { confirm = false })

for _, m in ipairs(mods) do
  if m.config then
    local ok, err = pcall(m.config)
    if not ok then
      vim.notify(('pack: config failed for plugins.%s\n%s'):format(m.name, err), vim.log.levels.ERROR)
    end
  end
end
-- vim: ts=2 sts=2 sw=2 et

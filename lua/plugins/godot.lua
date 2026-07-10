-- Godot 4 / GDScript IDE support. Syntax highlighting for .gd/.gdshader/
-- .tscn/.tres comes from treesitter (parsers registered in
-- plugins.treesitter) since core Neovim already ftdetects all of them; this
-- module wires up everything treesitter can't: the LSP connection, nvim as
-- Godot's external editor, GDScript formatting/linting, and gdshader
-- completion + :GodotRun commands (quickgd.nvim).
local M = {}

M.specs = {
  -- Small plugins, but only worth their startup cost inside an actual Godot
  -- project, so both stay off the runtimepath until the VimEnter check below
  -- finds a project.godot and loads them on demand.
  { src = 'https://github.com/QuickGD/quickgd.nvim', data = { lazy = true } },
  { src = 'https://github.com/mfussenegger/nvim-lint', data = { lazy = true } },
}

function M.config()
  -- quickgd.nvim's own filetype.add call for gdshaderinc is buggy (matches
  -- on a literal filename, not the extension); register it correctly here,
  -- unconditionally and early, so a .gdshaderinc passed on the command line
  -- ftdetects before any project-detection autocmd would fire.
  vim.filetype.add { extension = { gdshaderinc = 'gdshaderinc' } }

  -- Godot's style guide is tabs, 4 wide; override whatever vim-sleuth guesses
  -- for a brand-new, still-empty .gd file.
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'gdscript',
    group = vim.api.nvim_create_augroup('godot-indent', { clear = true }),
    callback = function()
      vim.bo.tabstop = 4
      vim.bo.shiftwidth = 4
      vim.bo.expandtab = false
    end,
  })

  -- The Godot editor embeds its own language server (TCP, default port
  -- 6005 — Editor Settings > Network > Language Server). nvim-lspconfig's
  -- bundled lsp/gdscript.lua just connects to it; there's no binary to
  -- install via Mason. Only attaches once a gdscript buffer is opened while
  -- the Godot editor has the project open.
  vim.lsp.enable 'gdscript'

  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('godot-server', { clear = true }),
    callback = function()
      local gdproject = io.open(vim.fn.getcwd() .. '/project.godot', 'r')
      if not gdproject then
        return
      end
      io.close(gdproject)

      -- Godot's "external editor" feature remote-controls whatever server is
      -- listening on ./godothost at the project root: clicking a script in
      -- the FileSystem dock, or a frame in a runtime error's stack trace,
      -- sends `:n {file}<CR>{line}G{col}|` to it. Auto-start that server so
      -- the jump works without manually running `nvim --listen ./godothost`.
      pcall(vim.fn.serverstart, './godothost')

      require('pack').load { 'quickgd.nvim', 'nvim-lint' }

      -- quickgd.nvim's `treesitter` option remaps the gdshader filetype's
      -- highlight language to 'glsl' — skip that, we already run the
      -- dedicated tree-sitter-gdshader grammar (plugins.treesitter). Its
      -- completion engine parses shaders with a hardcoded 'glsl' parser
      -- regardless of this flag, which is why 'glsl' is still in the
      -- treesitter parser list.
      -- pcall'd: on a brand-new install the 'glsl' parser may still be
      -- downloading (plugins.treesitter's install() is async), and quickgd's
      -- cmp module builds a treesitter query at require-time, which errors
      -- if the parser isn't there yet. A hard error here must not skip the
      -- nvim-lint setup below it; it self-heals on the next nvim launch once
      -- the parser has finished installing.
      local ok, setup_err = pcall(require('quickgd').setup, { treesitter = false })
      if not ok then
        vim.notify('quickgd.nvim setup failed (retries clean next launch):\n' .. tostring(setup_err), vim.log.levels.WARN)
      end

      -- gdlint (part of gdtoolkit, same install as gdformat -- see
      -- plugins.conform) for GDScript style linting: catches convention
      -- issues the LSP's diagnostics don't (naming, unused vars, line
      -- length). nvim-lint ships the 'gdlint' linter definition built in.
      -- gdlint reads the file on disk (stdin=false), so it's triggered on
      -- read/write only -- not InsertLeave, which would lint stale
      -- pre-save content against live buffer diagnostics.
      local lint = require 'lint'
      lint.linters_by_ft.gdscript = { 'gdlint' }
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost' }, {
        pattern = '*.gd',
        group = vim.api.nvim_create_augroup('godot-lint', { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  })
end

return M
-- vim: ts=2 sts=2 sw=2 et

return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- The `main` branch is the ground-up rewrite and the only branch that
    -- supports Neovim 0.12+. It drops the old `configs.setup` opts API: there
    -- is no `highlight`/`indent`/`auto_install` table. Parsers are installed
    -- imperatively and features are enabled per-buffer via a FileType autocmd.
    branch = 'main',
    lazy = false, -- main does not support lazy-loading
    build = ':TSUpdate',
    config = function()
      -- Parsers to keep installed. `install()` is asynchronous and a no-op for
      -- parsers that are already present, so running it on every startup is
      -- cheap (this replaces the old `ensure_installed` + `auto_install`).
      local parsers = {
        -- Core languages
        'c',
        'cpp',
        'lua',
        'vim',
        'vimdoc',
        'query',

        -- Web development
        'javascript',
        'typescript',
        'tsx',
        'html',
        'css',
        'scss',
        'astro',
        'vue',
        'svelte',

        -- Backend & Systems
        'python',
        'rust',
        'go',
        'java',
        'kotlin',
        'swift',
        'ruby',
        'php',
        'elixir',
        'erlang',
        'zig',
        'c_sharp',

        -- Shell & DevOps
        'bash',
        'fish',
        'dockerfile',
        'terraform',

        -- Data & Config
        'json',
        -- NOTE: `jsonc` is not a separate parser on the main branch; jsonc files
        -- fall back to regex highlighting (json parser would choke on comments).
        'yaml',
        'toml',
        'xml',
        'sql',
        'graphql',
        'jq',

        -- Markup & Documentation
        'markdown',
        'markdown_inline',
        'latex',
        'regex',

        -- Other useful
        'git_config',
        'git_rebase',
        'gitcommit',
        'gitignore',
        'diff',
      }
      require('nvim-treesitter').install(parsers)

      -- On `main`, highlighting/indentation are not global toggles — they must
      -- be enabled per-buffer. This autocmd starts treesitter for any filetype
      -- whose parser is installed, replacing the old `highlight.enable = true`.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
        callback = function(args)
          local buf = args.buf
          local ft = vim.bo[buf].filetype
          local lang = vim.treesitter.language.get_lang(ft) or ft

          -- Start treesitter highlighting only if a parser is available.
          -- `vim.treesitter.start` errors when no parser exists, so guard it.
          if not pcall(vim.treesitter.start, buf, lang) then
            return
          end

          if ft == 'ruby' then
            -- Ruby's treesitter highlighting is incomplete, so keep the regex
            -- syntax on top of it. `vim.treesitter.start` disables regex syntax
            -- by default, so re-enable it here. (Replaces the old
            -- `additional_vim_regex_highlighting = { 'ruby' }`.) The `syntax`
            -- option takes a filetype name (not 'on'). Defer it with schedule:
            -- set synchronously here it gets clobbered by the default
            -- FileType->syntax handling that runs right after this autocmd.
            -- Indentation is intentionally left to ruby's native ftplugin
            -- indentexpr — TS ruby indent is poor, which is why ruby was in the
            -- old `indent.disable` list.
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(buf) then
                vim.bo[buf].syntax = ft
              end
            end)
          else
            -- Experimental treesitter-based indentation (replaces the old
            -- `indent.enable = true`).
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- NOTE: folding is intentionally NOT wired to treesitter here — nvim-ufo
      -- owns folds (lsp/indent provider). See lua/custom/plugins/nvim-ufo.lua.
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et

-- Fuzzy Finder (files, lsp, etc)
local M = {}

M.specs = {
  {
    src = 'https://github.com/nvim-telescope/telescope.nvim',
    version = '0.1.x',
  },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope-ui-select.nvim' },
}

-- native fzf sorter (only when `make` is available, mirroring the old cond)
if vim.fn.executable 'make' == 1 then
  table.insert(M.specs, {
    src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
    data = { build = 'make' },
  })
end

if vim.g.have_nerd_font then
  table.insert(M.specs, { src = 'https://github.com/nvim-tree/nvim-web-devicons' })
end

function M.config()
  -- Originally lazy-loaded on VimEnter; defer the whole setup until the UI is up.
  vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = function()
      vim.schedule(function()
        local telescope = require 'telescope'
        local themes = require 'telescope.themes'
        local builtin = require 'telescope.builtin'

        -- Compat shim for nvim-treesitter `main`: telescope 0.1.x still calls the
        -- old master API that the rewrite removed. `preview.treesitter = false`
        -- (below) covers the previewer, but `current_buffer_fuzzy_find` (<leader>/)
        -- calls `nvim-treesitter.parsers.ft_to_lang` unconditionally, so back the
        -- few functions it needs with stock vim.treesitter. Telescope is the only
        -- consumer of these modules, so the shim is self-contained.
        local ok_parsers, ts_parsers = pcall(require, 'nvim-treesitter.parsers')
        if ok_parsers and type(ts_parsers) == 'table' and not ts_parsers.ft_to_lang then
          ts_parsers.ft_to_lang = function(ft)
            return vim.treesitter.language.get_lang(ft) or ft
          end
        end
        if not package.loaded['nvim-treesitter.configs'] then
          package.loaded['nvim-treesitter.configs'] = {
            is_enabled = function() return true end,
            get_module = function() return {} end,
          }
        end

        telescope.setup {
          defaults = {
            -- Use regex (not treesitter) highlighting in previews. Telescope
            -- 0.1.x's treesitter previewer calls the old nvim-treesitter master
            -- API (nvim-treesitter.parsers.ft_to_lang / .configs), which the
            -- main-branch rewrite removed — leaving it on errors every preview.
            -- Regex highlighting still colours previews (syntax is enabled).
            preview = { treesitter = false },
            -- follow symlinks in both file and grep pickers
            -- NOTE: These are Lua patterns, not regex! Escape dots with %. (a backslash does NOT escape).
            file_ignore_patterns = { '%.git', 'node_modules', '%.cache', '%.obsidian', '%.smart%-connections' },
            -- Centered float layout with larger preview
            layout_strategy = 'horizontal',
            layout_config = {
              horizontal = {
                prompt_position = 'top',
                width = 0.8,         -- 80% of screen width (matches Oil.nvim)
                height = 0.8,        -- 80% of screen height (matches Oil.nvim)
                preview_width = 0.6,  -- Preview takes 60% of the window
                preview_cutoff = 1,   -- Always show preview
              },
            },

            -- Border styling
            borderchars = {
              prompt  = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
              results = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
              preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
            },

            sorting_strategy = 'ascending',
            winblend = 0,
            vimgrep_arguments = {
              'rg',
              '--color=never',
              '--no-heading',
              '--with-filename',
              '--line-number',
              '--column',
              '--smart-case',
              '--follow',
            },
          },
          pickers = {
            -- make `:Telescope find_files` chase symlinks too
            find_files = {
              follow = true,
              hidden = false,
            },
          },
          extensions = {
            ['ui-select'] = themes.get_dropdown(),
          },
        }

        -- load extensions if available
        for _, ext in ipairs({ 'fzf', 'ui-select', 'obsidian', 'git_worktree' }) do
          pcall(telescope.load_extension, ext)
        end

        -- keymaps
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
        vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
        vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
        vim.keymap.set('n', '<leader>sF', function()
          builtin.find_files { hidden = true, no_ignore = true }
        end, { desc = '[S]earch [F]iles (incl. hidden + ignored)' })
        vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
        vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
        vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
        vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
        vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
        vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

        -- override default for current-buffer fuzzy-find
        vim.keymap.set('n', '<leader>/', function()
          builtin.current_buffer_fuzzy_find(themes.get_dropdown {
            winblend = 10,
            previewer = false,
          })
        end, { desc = '[/] Fuzzily search in current buffer' })

        -- live-grep in open files only
        vim.keymap.set('n', '<leader>s/', function()
          builtin.live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end, { desc = '[S]earch [/] in Open Files' })

        -- search Neovim config
        vim.keymap.set('n', '<leader>sn', function()
          builtin.find_files {
            cwd = vim.fn.resolve(vim.fn.stdpath 'config'),
            follow = true,
            hidden = false,
          }
        end, { desc = '[S]earch [N]eovim files' })
      end)
    end,
  })
end

return M
-- vim: ts=2 sts=2 sw=2 et

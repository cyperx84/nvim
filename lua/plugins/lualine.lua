local M = {}

M.specs = {
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
}

function M.config()
  -- Original lazy.nvim trigger: event = 'VeryLazy'
  vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = function()
      vim.schedule(function()
        require('lualine').setup {
          options = {
            theme = {
              normal = {
                a = { fg = '#ffffff', bg = '#1e3a8a', gui = 'bold' },
                b = { fg = '#1e3a8a', bg = '#292e42' },
                c = { fg = '#a9b1d6', bg = '#1a1b26' },
              },
              insert = {
                a = { fg = '#ffffff', bg = '#8b5cf6', gui = 'bold' },
                b = { fg = '#8b5cf6', bg = '#292e42' },
              },
              visual = {
                a = { fg = '#1a1b26', bg = '#bb9af7', gui = 'bold' },
                b = { fg = '#bb9af7', bg = '#292e42' },
              },
              replace = {
                a = { fg = '#1a1b26', bg = '#f7768e', gui = 'bold' },
                b = { fg = '#f7768e', bg = '#292e42' },
              },
              command = {
                a = { fg = '#1a1b26', bg = '#f7768e', gui = 'bold' },
                b = { fg = '#f7768e', bg = '#292e42' },
              },
              terminal = {
                a = { fg = '#1a1b26', bg = '#ff9500', gui = 'bold' },
                b = { fg = '#ff9500', bg = '#292e42' },
                c = { fg = '#a9b1d6', bg = '#1a1b26' },
              },
            },
            component_separators = { left = '│', right = '│' },
            section_separators = { left = '', right = '' },
            refresh = {
              statusline = 1000, -- Update every second for stable components
              tabline = 1000,
              winbar = 1000,
            },
            disabled_filetypes = {
              statusline = { 'NvimTree', 'dashboard', 'TelescopePrompt' },
            },
          },
          sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch', 'diff', 'diagnostics' },
            lualine_c = {
              {
                'filename',
                path = 1,
                symbols = {
                  modified = '●',
                  readonly = '🔒',
                  unnamed = '[No Name]',
                  newfile = '[New]',
                },
              },
              -- Add breadcrumb navigation if available
              {
                function()
                  local ok, navic = pcall(require, 'nvim-navic')
                  if ok and navic.is_available() then
                    return navic.get_location()
                  end
                  return ''
                end,
                cond = function()
                  local ok, navic = pcall(require, 'nvim-navic')
                  return ok and navic.is_available()
                end,
                color = { fg = '#a9b1d6' },
              },
            },
            lualine_x = {
              -- LSP status
              {
                function()
                  local clients = vim.lsp.get_clients()
                  if #clients > 0 then
                    return 'LSP' .. (#clients > 1 and '[' .. #clients .. ']' or '')
                  end
                  return ''
                end,
                color = { fg = '#7dcfff' },
              },
              { 'encoding', separator = { left = '│' } },
              { 'fileformat', separator = { left = '│' } },
              { 'filetype', separator = { left = '│' } },
              {
                function()
                  local noice_ok, noice = pcall(require, 'noice')
                  if noice_ok and noice.api.status.mode.has() then
                    return noice.api.status.mode.get()
                  end
                  return ''
                end,
                color = { fg = '#ff9e64' },
              },
            },
            lualine_y = { 'progress', 'searchcount' },
            lualine_z = { 'location' },
          },
          extensions = { 'fugitive', 'quickfix', 'fzf', 'lazy', 'mason', 'nvim-dap-ui', 'oil', 'trouble' },
        }
      end)
    end,
  })
end

return M

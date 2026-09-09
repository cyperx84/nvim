local M = {}

M.specs = {
  { src = 'https://github.com/nvim-lualine/lualine.nvim', data = { lazy = true } },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
}

-- Hoisted out of the mode component: allocating this table inside the
-- callback rebuilt it on every statusline redraw.
local MODE_ICONS = {
  n = '\u{f02dc} NORMAL',
  i = '\u{f03eb} INSERT',
  v = '\u{f06d0} VISUAL',
  V = '\u{f0279} V-LINE',
  [''] = '\u{f0d32} V-BLOCK',
  c = '\u{f07b7} COMMAND',
  R = '\u{f00e8} REPLACE',
  t = '\u{f018d} TERMINAL',
  s = '\u{f0485} SELECT',
  S = '\u{f0485} S-LINE',
}

local function apply()
  -- Off-rtp until here (data.lazy): the statusline renders slightly after
  -- first paint either way, so eager packadd bought nothing.
  require('pack').load { 'lualine.nvim' }
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
            component_separators = { left = '\u{e0c1}', right = '\u{e0c3}' },
            section_separators = { left = '\u{e0c0}', right = '\u{e0c2}' },
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
            lualine_a = {
              {
                function()
                  return MODE_ICONS[vim.fn.mode()] or vim.fn.mode()
                end,
              },
            },
            lualine_b = {
              { 'branch', icon = '\u{f062c}' },
              {
                'diff',
                symbols = { added = '\u{f0415} ', modified = '\u{f03eb} ', removed = '\u{f0374} ' },
              },
              {
                'diagnostics',
                symbols = {
                  error = '\u{f0159} ',
                  warn = '\u{f0026} ',
                  info = '\u{f02fc} ',
                  hint = '\u{f02d7} ',
                },
              },
            },
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
            },
            lualine_x = {
              -- LSP status
              {
                function()
                  -- Scoped to the current buffer: unscoped get_clients()
                  -- counted every attached client on every redraw.
                  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
                  if #clients > 0 then
                    return '\u{f0318} LSP' .. (#clients > 1 and '[' .. #clients .. ']' or '')
                  end
                  return ''
                end,
                color = { fg = '#7dcfff' },
              },
              { 'encoding', icon = '\u{f023b}', separator = { left = '\u{e0c1}' } },
              { 'fileformat', icons_enabled = true, separator = { left = '\u{e0c1}' } },
              { 'filetype', icon_only = false, colored = true, separator = { left = '\u{e0c1}' } },
            },
            lualine_y = {
              { 'progress', icon = '\u{f05da}', separator = { left = '\u{e0ba}' } },
              { 'searchcount', icon = '\u{f0349}' },
            },
            lualine_z = { { 'location', icon = '\u{f034e}', separator = { left = '\u{e0ba}' } } },
          },
            extensions = { 'quickfix', 'mason', 'nvim-dap-ui', 'oil' },
  }
end

function M.config()
  vim.api.nvim_create_autocmd('UIEnter', {
    once = true,
    callback = function()
      vim.schedule(apply)
    end,
  })
  vim.api.nvim_create_user_command('LualineReload', apply, {})
end

return M

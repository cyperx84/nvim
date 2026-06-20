-- The active colorscheme is the Neovim built-in 'unokai'; M.config() runs the
-- custom highlight setup directly (pack.lua runs configs in order, colorscheme
-- first, so no carrier plugin is needed as it was under lazy.nvim). These two
-- themes are kept installed/update-managed but lazy: off the runtimepath until
-- explicitly packadd'd, since neither is loaded at startup.
local M = {}

M.specs = {
  { src = 'https://github.com/folke/tokyonight.nvim', data = { lazy = true } },
  { src = 'https://github.com/loctvl842/monokai-pro.nvim', data = { lazy = true } },
}

function M.config()
  vim.cmd.colorscheme 'unokai'

  local colors = {
    border = '#0000ff',
    none = 'NONE',
  }

  local border_groups = {
    'WinSeparator',
    'FloatBorder',
    'TelescopeBorder',
    'TelescopePromptBorder',
    'TelescopeResultsBorder',
    'TelescopePreviewBorder',
  }

  local function set_custom_highlights()
    for _, group in ipairs(border_groups) do
      vim.api.nvim_set_hl(0, group, { fg = colors.border, bg = colors.none })
    end
    vim.api.nvim_set_hl(0, 'NormalFloat', { bg = colors.none })
  end

  set_custom_highlights()

  -- Re-apply after colorscheme changes only (not per-window/buffer)
  vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = '*',
    callback = set_custom_highlights,
  })
end

return M

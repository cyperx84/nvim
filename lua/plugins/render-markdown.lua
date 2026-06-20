local M = {}

M.specs = {
  { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
  -- Dependencies (shared with other modules; loader dedups by name).
  -- nvim-treesitter is pinned to 'main' to match the canonical declaration
  -- in the treesitter module (config migrated to the main-branch rewrite).
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/echasnovski/mini.icons' },
}

function M.config()
  -- Original lazy spec was ft = 'markdown'; defer setup until the first
  -- FileType. M.defer re-fires FileType on every already-open buffer so the
  -- plugin's own FileType handling sees any markdown files already loaded.
  require('pack').defer('FileType', function()
    vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#FB2C36', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#FF692A', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#50FA7B', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = '#BD93F9', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH5', { fg = '#0000FF', bold = true })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH6', { fg = '#9F9FA9', bold = true })

    -- Code block background only (let treesitter handle syntax colors)
    vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = '#121212' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', { bg = '#1a1a1a' })
    require('render-markdown').setup {
      heading = {
        border = false,
        border_virtual = false,
        border_prefix = false,
        above = '',
        below = '',
        backgrounds = {
          'RenderMarkdownH1',
          'RenderMarkdownH2',
          'RenderMarkdownH3',
          'RenderMarkdownH4',
          'RenderMarkdownH5',
          'RenderMarkdownH6',
        }, -- No background colors for headings
        foregrounds = {
          'RenderMarkdownH1',
          'RenderMarkdownH2',
          'RenderMarkdownH3',
          'RenderMarkdownH4',
          'RenderMarkdownH5',
          'RenderMarkdownH6',
        },
        width = 'block',
        left_pad = 2,
        right_pad = 2,
        min_width = 80,
        icons = { ' ', ' ', ' ', ' ', ' ', ' ' },
      },
      code = {
        enabled = true,
        sign = true,
        style = 'full', -- 'full' = background on whole block, 'normal' = treesitter highlighting
        position = 'left',
        language_pad = 0,
        disable_background = { 'diff' },
        width = 'full',
        left_pad = 1,
        right_pad = 1,
        min_width = 0,
        border = 'thin',
        highlight = 'RenderMarkdownCode', -- Background color only
        highlight_inline = 'RenderMarkdownCodeInline',
      },
      latex = { enabled = false },
      completions = { blink = { enabled = true } },
    }
  end, { pattern = 'markdown' })
end

return M

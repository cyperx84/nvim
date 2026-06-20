local M = {}

M.specs = {
  { src = 'https://github.com/kevinhwang91/nvim-ufo' },
  { src = 'https://github.com/kevinhwang91/promise-async' },
}

function M.config()
  -- Originally event = 'BufRead' under lazy.nvim: fold options and setup only
  -- applied once a real buffer was read. Same deferral here. The keymaps are
  -- defined eagerly but must require ufo lazily (the old rhs values
  -- `require('ufo').openAllFolds` would pull the module in at startup).
  require('pack').defer('BufReadPost', function()
    vim.o.foldcolumn = '0' -- disabled fold column numbers
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    require('ufo').setup {
      provider_selector = function(_, _, _)
        return { 'lsp', 'indent' }
      end,
    }
  end)

  vim.keymap.set('n', 'zR', function()
    require('ufo').openAllFolds()
  end, { desc = 'Open all folds' })
  vim.keymap.set('n', 'zM', function()
    require('ufo').closeAllFolds()
  end, { desc = 'Close all folds' })
  vim.keymap.set('n', 'zK', function()
    local winid = require('ufo').peekFoldedLinesUnderCursor()
    if not winid then
      vim.lsp.buf.hover()
    end
  end, { desc = 'Peek Fold' })
end

return M

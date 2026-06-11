local M = {}

M.specs = {
  { src = 'https://github.com/stevearc/conform.nvim' },
}

function M.config()
  -- Originally event = { 'BufReadPre', 'BufNewFile' } under lazy.nvim: setup
  -- only ran once a real buffer was opened, keeping dashboard-only startups
  -- free of this cost. Same deferral here; the keymap is defined eagerly.
  vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
    once = true,
    callback = function()
      require('conform').setup {
        formatters_by_ft = {
          lua = { 'stylua' },
          svelte = { 'prettierd', 'prettier', stop_after_first = true },
          astro = { 'prettierd', 'prettier', stop_after_first = true },
          javascript = { 'prettierd', 'prettier', stop_after_first = true },
          typescript = { 'prettierd', 'prettier', stop_after_first = true },
          javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
          typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
          json = { 'prettierd', 'prettier', stop_after_first = true },
          graphql = { 'prettierd', 'prettier', stop_after_first = true },
          markdown = { 'prettierd', 'prettier', stop_after_first = true },
          erb = { 'htmlbeautifier' },
          html = { 'htmlbeautifier' },
          bash = { 'beautysh' },
          proto = { 'buf' },
          rust = { 'rustfmt' },
          yaml = { 'yamlfix' },
          toml = { 'taplo' },
          css = { 'prettierd', 'prettier', stop_after_first = true },
          scss = { 'prettierd', 'prettier', stop_after_first = true },
          sh = { 'shfmt' },
          go = { 'gofmt' },
          xml = { 'xmllint' },
        },
      }
    end,
  })

  vim.keymap.set({ 'n', 'v' }, '<leader>l', function()
    require('conform').format {
      lsp_format = 'fallback',
      async = false,
      timeout_ms = 1000,
    }
  end, { desc = 'Format file or range (in visual mode)' })
end

return M -- vim: ts=2 sts=2 sw=2 et

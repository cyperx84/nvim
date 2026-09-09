local M = {}

M.specs = {
  { src = 'https://github.com/folke/lazydev.nvim' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/j-hui/fidget.nvim' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
}

function M.config()
  -- lazydev.nvim: was ft = 'lua' under lazy.nvim; keep the FileType gate.
  -- NOTE: lazydev may assume lazy.nvim internals; verify at boot.
  require('pack').defer('FileType', function()
    require('lazydev').setup {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    }
  end, { pattern = 'lua' })

  -- Mason (LSP/tool installer) is kept off the startup critical path: it loads
  -- on its own commands, and the installer bridges are required lazily from the
  -- deferred setup at the end of lspconfig's config().
  -- (Under vim.pack the cmd-only trigger is gone, so setup runs eagerly here;
  -- the installer bridges below are still deferred via vim.schedule.)
  require('mason').setup {}

  -- LSP progress UI: only needed once a language server attaches, so defer
  -- setup to the first LspAttach (was event = 'LspAttach' under lazy.nvim) —
  -- no-LSP/dashboard-only startups never pay for it.
  require('pack').defer('LspAttach', function()
    require('fidget').setup {}
  end)

  -- nvim-lspconfig (eager: LSP stays on the startup path by user preference)
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end
      map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
      map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
      map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
      map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
      map('<leader>so', require('telescope.builtin').lsp_document_symbols, '[S]earch D[o]cument Symbols')
      map('<leader>sW', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[S]earch [W]orkspace Symbols')
      map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
      map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      ---@param client vim.lsp.Client
      ---@param method vim.lsp.protocol.Method
      ---@param bufnr? integer some lsp support methods only in specific files
      ---@return boolean
      local function client_supports_method(client, method, bufnr)
        if vim.fn.has 'nvim-0.11' == 1 then
          return client:supports_method(method, bufnr)
        else
          return client.supports_method(method, { bufnr = bufnr })
        end
      end
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = function()
            -- Safety check: only clear references if buffer is valid and not a special buffer
            local buftype = vim.bo[event.buf].buftype
            local filetype = vim.bo[event.buf].filetype

            -- Skip special buffers (dashboard, terminals, etc.)
            if filetype == 'snacks_dashboard' or (buftype ~= '' and buftype ~= 'acwrite') then
              return
            end

            pcall(vim.lsp.buf.clear_references)
          end,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end
      if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- Single-line borders for LSP hover/signature (and other) floats.
  -- The old vim.lsp.with()/vim.lsp.handlers[...] override is deprecated in
  -- 0.11+ and warns on 0.12; vim.o.winborder is the supported replacement.
  vim.o.winborder = 'single'

  -- Make float windows transparent
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'FloatBorder', { fg = 'NONE', bg = 'none' })

  -- Remove terminal window borders
  vim.api.nvim_create_autocmd('TermOpen', {
    group = vim.api.nvim_create_augroup('terminal-config', { clear = true }),
    callback = function()
      vim.opt_local.signcolumn = 'no'
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
    end,
  })

  vim.diagnostic.config {
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = vim.diagnostic.severity.ERROR },
    signs = vim.g.have_nerd_font and {
      text = {
        [vim.diagnostic.severity.ERROR] = '󰅚 ',
        [vim.diagnostic.severity.WARN] = '󰀪 ',
        [vim.diagnostic.severity.INFO] = '󰋽 ',
        [vim.diagnostic.severity.HINT] = '󰌶 ',
      },
    } or {},
    virtual_text = {
      source = 'if_many',
      spacing = 2,
      format = function(diagnostic)
        local diagnostic_message = {
          [vim.diagnostic.severity.ERROR] = diagnostic.message,
          [vim.diagnostic.severity.WARN] = diagnostic.message,
          [vim.diagnostic.severity.INFO] = diagnostic.message,
          [vim.diagnostic.severity.HINT] = diagnostic.message,
        }
        return diagnostic_message[diagnostic.severity]
      end,
    },
  }

  local capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('blink.cmp').get_lsp_capabilities())
  -- Enable folding range for nvim-ufo
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }

  local servers = {
    clangd = {},
    pyright = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = 'basic',
          },
        },
      },
    },
    rust_analyzer = {},
    marksman = {},

    lua_ls = {
      -- cmd = { ... },
      -- filetypes = { ... },
      -- capabilities = {},
      settings = {
        Lua = {
          completion = {
            callSnippet = 'Replace',
          },
          -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
          -- diagnostics = { disable = { 'missing-fields' } },
        },
      },
    },
  }

  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    'stylua', -- Used to format Lua code
    'gdtoolkit', -- gdformat + gdlint for GDScript (plugins.conform / plugins.godot)
  })

  -- Apply capabilities to all servers globally (nvim 0.11+ API)
  vim.lsp.config('*', { capabilities = capabilities })

  -- Apply per-server custom settings
  for server_name, server_config in pairs(servers) do
    if next(server_config) ~= nil then
      vim.lsp.config(server_name, server_config)
    end
  end

  -- Enable all servers
  vim.lsp.enable(vim.tbl_keys(servers))

  -- Defer the Mason-backed installer machinery off the startup critical
  -- path. Servers still attach immediately via vim.lsp.enable above; this
  -- only auto-installs missing servers/tools, which can wait a tick.
  vim.schedule(function()
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    require('mason-lspconfig').setup {
      ensure_installed = {},
      automatic_enable = false,
    }
  end)
end

return M
-- vim: ts=2 sts=2 sw=2 et

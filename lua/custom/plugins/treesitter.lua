return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    -- Pin to master: the `main` branch is a full, incompatible rewrite that drops
    -- the opts/highlight/indent API below. Without this pin, an upstream default-
    -- branch flip to `main` would break this config with no change on our side.
    branch = 'master',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = {
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
        'jsonc',
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
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et

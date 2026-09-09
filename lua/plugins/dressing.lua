-- Retired module — kept as a tombstone on purpose: dressing.nvim previously
-- owned vim.ui.select (archived upstream, confirmed via GitHub API 2025-08).
-- telescope-ui-select (telescope.lua) is now the sole owner, so vim.ui.select
-- routes to one backend deterministically.
--
-- To undo: restore the setup block from git history and re-add
--   { src = 'https://github.com/stevearc/dressing.nvim' },
return {}

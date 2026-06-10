local M = {}

M.specs = {
	{ src = 'https://github.com/brenoprata10/nvim-highlight-colors' },
}

function M.config()
	require('nvim-highlight-colors').setup({
		render = 'background',
		enable_hex = true,
		enable_short_hex = true,
		enable_rgb = true,
		enable_hsl = true,
		enable_var_usage = true,
	})
end

return M

local M = {}

M.specs = {
	{ src = 'https://github.com/brenoprata10/nvim-highlight-colors' },
}

function M.config()
	-- Originally event = { 'BufReadPost', 'BufNewFile' } under lazy.nvim;
	-- same deferral so dashboard-only startups skip the setup cost.
	vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
		once = true,
		callback = function()
			require('nvim-highlight-colors').setup({
				render = 'background',
				enable_hex = true,
				enable_short_hex = true,
				enable_rgb = true,
				enable_hsl = true,
				enable_var_usage = true,
			})
		end,
	})
end

return M

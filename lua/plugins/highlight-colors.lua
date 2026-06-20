local M = {}

M.specs = {
  { src = 'https://github.com/brenoprata10/nvim-highlight-colors' },
}

function M.config()
  -- Originally event = { 'BufReadPost', 'BufNewFile' } under lazy.nvim;
  -- same deferral so dashboard-only startups skip the setup cost. M.defer
  -- re-fires the trigger so the first opened file gets highlighted on load.
  require('pack').defer({ 'BufReadPost', 'BufNewFile' }, function()
    require('nvim-highlight-colors').setup {
      render = 'background',
      enable_hex = true,
      enable_short_hex = true,
      enable_rgb = true,
      enable_hsl = true,
      enable_var_usage = true,
    }
  end)
end

return M

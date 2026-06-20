local M = {}

M.specs = {
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
}

function M.config()
  -- Originally event = { 'BufReadPost', 'BufNewFile' } under lazy.nvim;
  -- same deferral so dashboard-only startups skip the setup cost. M.defer
  -- re-fires the trigger so the first opened file gets indent guides on load.
  require('pack').defer({ 'BufReadPost', 'BufNewFile' }, function()
    require('ibl').setup {}
  end)
end

return M

local M = {}

M.specs = {
  { src = 'https://github.com/windwp/nvim-autopairs' },
}

function M.config()
  -- Originally lazy-loaded on InsertEnter; preserve that trigger.
  require('pack').defer('InsertEnter', function()
    require('nvim-autopairs').setup {}
  end)
end

return M

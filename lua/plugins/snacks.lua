local splash_name
local boot_ms -- cached so dashboard re-renders (resize, splits) keep a stable number

local M = {}

M.specs = {
  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/amansingh-afk/milli.nvim" },
}

function M.config()
  -- init: rename integration with Oil (ran at startup under lazy)
  vim.api.nvim_create_autocmd("User", {
    pattern = "OilActionsPost",
    callback = function(event)
      if event.data.actions.type == "move" then
        Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
      end
    end,
  })

  local milli = require("milli")
  -- Curated to a uniform 50-wide, ~19-25 tall set so the dashboard lays out
  -- identically on every launch. Also kept lightweight (≤152 frames) so the
  -- startup splash-parse stays fast — `lights` (501 frames, ~5x the load cost)
  -- was dropped for this reason. Other outliers excluded: width (attackontitan
  -- 84, skeleton 80, skulltwo 40), height (blackhole 14, flyingdragon 45) and
  -- the 60-wide group (dancerramp/finger/robot).
  local all = {
    "aiface", "shader", "lighningtornado", "skullone",
  }
  -- LuaJIT's math.random isn't auto-seeded, so without this every launch
  -- picks the same index. hrtime() is a high-entropy per-launch seed.
  math.randomseed(vim.loop.hrtime())
  splash_name = all[math.random(#all)]
  local splash = milli.load({ splash = splash_name })
  local opts = {
    bigfile = { enabled = true },
    picker = { enabled = false },  -- Disabled due to dimension validation issues - use Telescope instead
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        max_width = 80,
        max_height = 40,
      },
      resolve = function(path, src)
        local ok, obsidian_api = pcall(require, "obsidian")
        if ok and obsidian_api and obsidian_api.api and obsidian_api.api.path_is_note(path) then
          local resolved = obsidian_api.api.resolve_image_path(src)
          if resolved and vim.fn.filereadable(resolved) == 1 then
            return resolved
          end
        end

        local vault_root = vim.fn.expand('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes')
        local fallback_path = vault_root .. '/' .. src
        if vim.fn.filereadable(fallback_path) == 1 then
          return fallback_path
        end

        return src
      end,
    },
    dashboard = {
      -- Pane follows the splash width so wider art still centers (snacks
      -- defaults to 60 and left-pins anything wider). Min 60 keeps the menu
      -- and recent-file paths readable — a safety net if a wide splash is added.
      width = math.max(splash.cols or 60, 60),
      preset = {
        pick = nil,
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "s", desc = "Search Files", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = "󰒲 ", key = "u", desc = "Update Plugins", action = ":lua vim.pack.update()" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        header = table.concat(splash.frames[1], "\n"),
      },
      sections = {
        { section = 'header' },
        {
          section = "keys",
          indent = 1,
          padding = 1,
        },
        { section = 'recent_files', icon = ' ', title = 'Recent Files', indent = 3, padding = 2 },
        -- snacks' builtin 'startup' section hard-requires lazy.nvim
        -- (lazy.stats), which errored on every render under vim.pack.
        -- Render the same footer line from vim.pack data instead.
        {
          function()
            boot_ms = boot_ms
              or (vim.g.boot_hrtime and math.floor((vim.uv.hrtime() - vim.g.boot_hrtime) / 1e4 + 0.5) / 100)
              or 0
            return {
              align = "center",
              text = {
                { "⚡ Neovim loaded ", hl = "footer" },
                { tostring(#vim.pack.get()), hl = "special" },
                { " plugins in ", hl = "footer" },
                { boot_ms .. "ms", hl = "special" },
              },
            }
          end,
        },
      },
    },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = false },
    notifier = { enabled = false },
    quickfile = { enabled = true },
    scope = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
    rename = { enabled = true },
    zen = {
      enabled = true,
      toggles = {
        ufo             = true,
        dim             = true,
        git_signs       = false,
        diagnostics     = false,
        line_number     = false,
        relative_number = false,
        signcolumn      = "no",
        indent          = false
      }
    },
    terminal = {
      win = {
        style = "terminal",
        wo = {
          winhighlight = "Normal:Normal,NormalNC:Normal",
        },
      },
    },
  }

  require("snacks").setup(opts)

  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

  -- Animate the splash so it follows snacks' header on window reflow (e.g.
  -- opening a vertical split). See lua/custom/milli_follow.lua for why.
  require("custom.milli_follow").attach(splash_name)

  Snacks.toggle.new({
    id = "ufo",
    name = "Enable/Disable ufo",
    get = function()
      return require("ufo").inspect()
    end,
    set = function(state)
      if state == nil then
        require("noice").enable()
        require("ufo").enable()
        vim.o.foldenable = true
        vim.o.foldcolumn = "1"
      else
        require("noice").disable()
        require("ufo").disable()
        vim.o.foldenable = false
        vim.o.foldcolumn = "0"
      end
    end,
  })

  -- Keymaps (from lazy keys = {...})
  vim.keymap.set("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Buffer delete" })
  vim.keymap.set("n", "<leader>ba", function() Snacks.bufdelete.all() end, { desc = "Buffer delete all" })
  vim.keymap.set("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Buffer delete other" })
  vim.keymap.set("n", "<leader>tz", function() Snacks.zen() end, { desc = "Toggle Zen Mode" })
  vim.keymap.set("n", "<leader>tT", function() Snacks.terminal.toggle() end, { desc = "Toggle Terminal" })
end

return M

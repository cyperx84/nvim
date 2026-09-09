local splash_name
local boot_ms -- cached so dashboard re-renders (resize, splits) keep a stable number

local M = {}

M.specs = {
  { src = 'https://github.com/folke/snacks.nvim' },
  { src = 'https://github.com/amansingh-afk/milli.nvim' },
}

function M.config()
  -- init: rename integration with Oil (ran at startup under lazy)
  vim.api.nvim_create_autocmd('User', {
    pattern = 'OilActionsPost',
    callback = function(event)
      if event.data.actions.type == 'move' then
        Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
      end
    end,
  })

  local milli = require 'milli'
  -- Curated to a uniform 50-wide, ~19-25 tall set so the dashboard lays out
  -- identically on every launch. Also kept lightweight (≤152 frames) so the
  -- startup splash-parse stays fast — `lights` (501 frames, ~5x the load cost)
  -- was dropped for this reason. Other outliers excluded: width (attackontitan
  -- 84, skeleton 80, skulltwo 40), height (blackhole 14, flyingdragon 45) and
  -- the 60-wide group (dancerramp/finger/robot).
  -- Preferred (curated for a uniform ~50-wide layout). Upstream milli.nvim
  -- 6e94122 slimmed to 6 bundled splashes and moved these to its install-on-demand
  -- registry — so instead of depending on :MilliInstall (per-machine local state),
  -- we vendor them in this repo at lua/milli/splashes/*.lua. nvim's runtimepath
  -- loader finds them there like any bundled splash, so they travel with the
  -- config to every machine. See that dir; re-fetch with :MilliInstall <name>.
  local preferred = {
    'aiface',
    'shader',
    'lighningtornado',
    'skullone',
  }
  -- Always-available fallback: the currently bundled splashes. Guarantees the
  -- dashboard renders even before any registry splash is installed.
  local bundled = { 'fire', 'vibecat', 'blackhole', 'skeleton', 'dancerramp', 'finger' }
  -- LuaJIT's math.random isn't auto-seeded, so without this every launch
  -- picks the same index. hrtime() is a high-entropy per-launch seed.
  math.randomseed(vim.loop.hrtime())

  -- Pick a random splash that actually loads. Upstream can move a name to the
  -- registry (or drop it), so probe candidates and skip any that fail rather
  -- than letting a missing splash abort startup. Preferred pool first, then
  -- bundled as a safety net.
  local function pick(pool)
    pool = vim.deepcopy(pool)
    while #pool > 0 do
      local i = math.random(#pool)
      local name = pool[i]
      local ok, data = pcall(milli.load, { splash = name })
      if ok and data and data.frames then return name, data end
      table.remove(pool, i)
    end
  end
  local splash
  splash_name, splash = pick(preferred)
  if not splash then splash_name, splash = pick(bundled) end
  -- Last-resort stub so the rest of config never indexes nil (all splashes
  -- somehow unavailable). One blank frame → snacks shows its default header.
  if not splash then
    splash_name = nil
    splash = { cols = 60, frames = { { '' } } }
  end
  local opts = {
    bigfile = { enabled = true },
    picker = { enabled = false }, -- Disabled due to dimension validation issues - use Telescope instead
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        max_width = 80,
        max_height = 40,
      },
      resolve = function(path, src)
        local ok, obsidian_api = pcall(require, 'obsidian')
        if ok and obsidian_api and obsidian_api.api and obsidian_api.api.path_is_note(path) then
          local resolved = obsidian_api.api.resolve_image_path(src)
          if resolved and vim.fn.filereadable(resolved) == 1 then
            return resolved
          end
        end

        local vault_root = vim.fn.expand '~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes'
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
          { icon = ' ', key = 's', desc = 'Search Files', action = ":lua Snacks.dashboard.pick('files')" },
          { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
          { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = '󰒲 ', key = 'u', desc = 'Update Plugins', action = ':lua vim.pack.update()' },
          { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
        },
        header = table.concat(splash.frames[1], '\n'),
      },
      sections = {
        { section = 'header' },
        {
          section = 'keys',
          indent = 1,
          padding = 1,
        },
        { section = 'recent_files', icon = ' ', title = 'Recent Files', indent = 3, padding = 2 },
        -- snacks' builtin 'startup' section hard-requires lazy.nvim
        -- (lazy.stats), which errored on every render under vim.pack.
        -- Render the same footer line from vim.pack data instead.
        {
          function()
            boot_ms = boot_ms or (vim.g.boot_hrtime and math.floor((vim.uv.hrtime() - vim.g.boot_hrtime) / 1e4 + 0.5) / 100) or 0
            return {
              align = 'center',
              text = {
                { '⚡ Neovim loaded ', hl = 'footer' },
                -- info=false is critical: info=true shells out to git per
                -- plugin (~300ms for 56 plugins) on every dashboard render.
                { tostring(#vim.pack.get(nil, { info = false })), hl = 'special' },
                { ' plugins in ', hl = 'footer' },
                { boot_ms .. 'ms', hl = 'special' },
              },
            }
          end,
        },
      },
    },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = false },
    -- Sole messaging pipeline (noice + nvim-notify retired into noice.lua as
    -- off-rtp flip-backs). Styled notifications, inline in the corner.
    notifier = {
      enabled = true,
      timeout = 3000,
      style = 'compact',
      -- Carried over from the old noice routes: suppress the noisy LSP-hover
      -- "No information available" spam and the terminal-open chatter.
      filter = function(n)
        local msg = n.msg or ''
        return not (msg:find('No information available', 1, true)
          or msg:find('Native terminal opened', 1, true))
      end,
    },
    -- noice's other former jobs are covered elsewhere: message routing lives
    -- in vim.o.cmdheight/messages default behavior + :messages keymap below;
    -- lsp_doc_border is covered by vim.o.winborder (lspconfig).
    quickfile = { enabled = true },
    scope = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
    rename = { enabled = true },
    zen = {
      enabled = true,
      toggles = {
        ufo = true,
        dim = true,
        git_signs = false,
        diagnostics = false,
        line_number = false,
        relative_number = false,
        signcolumn = 'no',
        indent = false,
      },
    },
    terminal = {
      win = {
        style = 'terminal',
        wo = {
          winhighlight = 'Normal:Normal,NormalNC:Normal',
        },
      },
    },
  }

  require('snacks').setup(opts)

  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

  -- Animate the splash so it follows snacks' header on window reflow (e.g.
  -- opening a vertical split). See lua/custom/milli_follow.lua for why.
  require('custom.milli_follow').attach(splash_name)

  Snacks.toggle.new {
    id = 'ufo',
    name = 'Enable/Disable ufo',
    -- ufo.inspect() returns a fold-info TABLE (always truthy), so it can't
    -- report toggle state; vim.o.foldenable is the actual switch. The old
    -- set() body also called noice enable/disable — copy-paste from a noice
    -- toggle, unrelated to folds.
    get = function()
      return vim.o.foldenable and require('ufo').enableFold ~= nil
    end,
    set = function(state)
      if state then
        require('ufo').enable()
        vim.o.foldenable = true
        vim.o.foldcolumn = '1'
      else
        require('ufo').disable()
        vim.o.foldenable = false
        vim.o.foldcolumn = '0'
      end
    end,
  }

  -- Keymaps (from lazy keys = {...})
  vim.keymap.set('n', '<leader>bd', function()
    Snacks.bufdelete()
  end, { desc = 'Buffer delete' })
  vim.keymap.set('n', '<leader>ba', function()
    Snacks.bufdelete.all()
  end, { desc = 'Buffer delete all' })
  vim.keymap.set('n', '<leader>bo', function()
    Snacks.bufdelete.other()
  end, { desc = 'Buffer delete other' })
  vim.keymap.set('n', '<leader>tz', function()
    Snacks.zen()
  end, { desc = 'Toggle Zen Mode' })
  vim.keymap.set('n', '<leader>tT', function()
    Snacks.terminal.toggle()
  end, { desc = 'Toggle Terminal' })
  -- Replaces noice's <leader>z NoiceDismiss now that snacks.notifier owns
  -- messaging.
  vim.keymap.set('n', '<leader>z', function()
    Snacks.notifier.hide()
  end, { desc = 'Dismiss Notifications' })
end

return M

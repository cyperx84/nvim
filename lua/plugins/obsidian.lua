-- =============================================================================
-- Obsidian.nvim Configuration
-- =============================================================================
-- Plugin: https://github.com/obsidian-nvim/obsidian.nvim
-- Requires: ripgrep (rg) for search functionality
-- =============================================================================

local M = {}

-- =============================================================================
-- LOCAL HELPER FUNCTIONS
-- =============================================================================

--- Rename the current note (updates frontmatter id/title and filename)
---@return nil
local function rename_note()
  vim.ui.input({ prompt = 'New note name: ' }, function(new_name)
    if not new_name or new_name == '' then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local current_file = vim.api.nvim_buf_get_name(bufnr)
    local current_dir = vim.fn.fnamemodify(current_file, ':h')
    local new_path = current_dir .. '/' .. new_name .. '.md'

    -- Allow case-only renames on macOS (filesystem is case-insensitive)
    local is_case_only_rename = current_file:lower() == new_path:lower()
    if vim.fn.filereadable(new_path) == 1 and not is_case_only_rename then
      vim.notify('Error: File "' .. new_name .. '.md" already exists', vim.log.levels.ERROR)
      return
    end

    local save_ok, save_err = pcall(vim.cmd, 'w')
    if not save_ok then
      vim.notify('Error: Failed to save current file: ' .. tostring(save_err), vim.log.levels.ERROR)
      return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local new_id = new_name:gsub('^%s*(.-)%s*$', '%1'):gsub('%s+', '-'):gsub('[^%w%-]', '')

    -- Update frontmatter fields
    for i = 1, #lines do
      if lines[i]:match '^id:' then
        lines[i] = 'id: ' .. new_id
      elseif lines[i]:match '^title:' then
        lines[i] = 'title: ' .. new_name
      end
    end

    local write_ok = pcall(vim.fn.writefile, lines, current_file)
    if not write_ok then
      vim.notify('Error: Failed to write file', vim.log.levels.ERROR)
      return
    end

    if current_file ~= new_path then
      vim.fn.system('mv ' .. vim.fn.shellescape(current_file) .. ' ' .. vim.fn.shellescape(new_path))
    end

    pcall(vim.cmd, 'edit ' .. vim.fn.fnameescape(new_path))
    vim.notify('Renamed to: ' .. new_name, vim.log.levels.INFO)
  end)
end

--- Toggle checkbox on multiple lines (visual mode helper)
---@param start_line integer
---@param end_line integer
---@return nil
local function toggle_checkboxes_range(start_line, end_line)
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
  for line = start_line, end_line do
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    require('obsidian').util.toggle_checkbox()
  end
end

--- Resolve a directory link under the cursor to a real directory.
---
--- OKF index files link to directories (`[notes/](/notes/)`), and obsidian.nvim
--- has no concept of those: it appends `.md`, fails to resolve `notes/.md`, and
--- prompts to CREATE a note — which silently litters the vault with junk notes.
--- Detect them before obsidian sees them.
---@return string|nil dir absolute directory, or nil if the cursor isn't on one
local function cursor_dir_link()
  local ok, obsidian_api = pcall(require, 'obsidian.api')
  if not ok then
    return nil
  end
  local link = obsidian_api.cursor_link()
  if not link then
    return nil
  end
  local location = require('obsidian.util').parse_link(link)
  if not location or not location:match '/$' then
    return nil
  end

  local vault = _G.Obsidian and _G.Obsidian.dir and tostring(_G.Obsidian.dir) or nil
  local candidates = {}
  if vim.startswith(location, '/') then
    -- OKF root-absolute: relative to the vault, not the filesystem.
    if vault then
      candidates[#candidates + 1] = vault .. location
    end
  else
    candidates[#candidates + 1] = vim.fs.joinpath(vim.fn.expand '%:p:h', location)
    if vault then
      candidates[#candidates + 1] = vim.fs.joinpath(vault, location)
    end
  end

  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  return nil
end

--- Browse a directory (netrw is disabled in lua/pack.lua, so `:edit <dir>` would
--- just open an empty buffer).
---@param dir string
---@return nil
local function open_dir(dir)
  local ok, oil = pcall(require, 'oil')
  if ok then
    oil.open(dir)
  else
    vim.cmd.edit(vim.fn.fnameescape(dir))
  end
end

--- Install the link-following keymaps for a markdown buffer.
---
--- Applied twice: once on FileType (so plain markdown outside the vault still
--- gets a sane `gf`) and again on `ObsidianNoteEnter`, which fires at the end of
--- obsidian's own attach — that's the only way to win over the `<CR>` mapping it
--- installs there itself.
---@return nil
local function apply_link_keymaps()
  vim.keymap.set('n', 'gf', function()
    local dir = cursor_dir_link()
    if dir then
      return open_dir(dir)
    end
    if vim.b.obsidian_buffer then
      vim.cmd 'Obsidian follow_link'
    else
      vim.cmd 'normal! gf'
    end
  end, { buffer = true, desc = 'Follow link under cursor' })

  vim.keymap.set('n', '<cr>', function()
    local dir = cursor_dir_link()
    if dir then
      -- Defer: an expr mapping may not change buffers while it's being evaluated.
      vim.schedule(function()
        open_dir(dir)
      end)
      return ''
    end
    return require('obsidian').util.smart_action()
  end, { buffer = true, expr = true, desc = 'Smart action' })
end

-- =============================================================================
-- PLUGIN SPECIFICATION
-- =============================================================================

M.specs = {
  {
    src = 'https://github.com/obsidian-nvim/obsidian.nvim',
    version = vim.version.range '*',
  },
}

function M.config()
  -- Originally ft = 'markdown' under lazy.nvim: defer setup until the first
  -- markdown buffer, then re-fire FileType for that buffer so the buffer-local
  -- settings/keymaps below apply to it.
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    once = true,
    callback = function(ev)
      -- =========================================================================
      -- CORE SETUP
      -- =========================================================================
      require('obsidian').setup {
        -- Workspaces
        -- One vault, any structure under it: obsidian manages frontmatter there
        -- and nowhere else, so code repos, dotfiles, and ~/.config stay
        -- untouched. To relocate the vault later, change this one path.
        workspaces = {
          { name = 'notes', path = vim.fn.expand '~/vaults/CyperX' },
        },

        -- Daily notes
        daily_notes = {
          folder = 'inbox',
          date_format = '%Y-%m-%d',
          alias_format = '%B %-d, %Y',
          default_tags = { 'daily-note' },
        },

        -- Completion (served by the built-in obsidian-ls LSP server, surfaced
        -- through blink.cmp's `lsp` source; the old `completion.blink` opt is
        -- deprecated and stripped by the fork)
        completion = {
          min_chars = 2,
        },

        -- Note creation
        new_notes_location = 'current_dir',

        -- Note ID: URL-friendly slugs
        note_id_func = function(title)
          if title == nil or title == '' then
            return tostring(os.time())
          end
          return title:gsub('^%s*(.-)%s*$', '%1'):gsub('%s+', '-'):gsub('[^%w%-]', '')
        end,

        -- Frontmatter
        frontmatter = {
          -- Manage frontmatter for notes anywhere in the vault. Markdown outside
          -- it — code repos, dotfiles, ~/.config — is never touched, since
          -- obsidian only activates inside a workspace.
          enabled = true,

          func = function(note)
            local now = os.date '%Y-%m-%d %H:%M'
            -- OKF (Open Knowledge Format) wants a strict ISO 8601 UTC timestamp
            -- alongside the human-readable created/modified pair.
            local now_iso = os.date '!%Y-%m-%dT%H:%M:%SZ'
            local out = {
              id = note.id,
              type = (note.metadata and note.metadata.type) or 'Note',
              title = note.title or '',
              description = (note.metadata and note.metadata.description) or nil,
              created = (note.metadata and note.metadata.created) or now,
              modified = now,
              timestamp = now_iso,
              reviewed = (note.metadata and note.metadata.reviewed) or nil,
              tags = note.tags or {},
              topics = (note.metadata and note.metadata.topics) or {},
              refs = (note.metadata and note.metadata.refs) or {},
              aliases = note.aliases or {},
              base = (note.metadata and note.metadata.base) or nil,
            }

            -- Preserve custom metadata fields
            if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
              local handled = { 'description', 'created', 'modified', 'timestamp', 'reviewed', 'topics', 'refs', 'base' }
              for k, v in pairs(note.metadata) do
                if not vim.tbl_contains(handled, k) then
                  out[k] = v
                end
              end
            end

            return out
          end,
        },

        -- Attachments
        attachments = {
          folder = 'assets/imgs',
          img_name_func = function()
            return os.date '%Y-%m-%d-%H%M%S'
          end,
          img_text_func = function(path)
            local filename = vim.fn.fnamemodify(path.filename, ':t')
            return string.format('![%s](assets/imgs/%s)', path.name, filename)
          end,
        },

        -- Link style: Use markdown links [text](file.md) instead of wiki [[links]]
        link = { style = 'markdown' },

        -- Picker (telescope)
        picker = {
          name = 'telescope.nvim',
          note_mappings = { new = '<C-x>', insert_link = '<C-l>' },
          tag_mappings = { tag_note = '<C-x>', insert_tag = '<C-l>' },
        },

        -- Search/sort (sort_by/sort_reversed live under `search`, not `picker`)
        search = {
          sort_by = 'modified',
          sort_reversed = true,
        },

        -- UI (disabled in favor of render-markdown.nvim)
        ui = { enable = false },

        legacy_commands = false,
      }

      -- =========================================================================
      -- MARKDOWN FILE SETTINGS & KEYMAPS
      -- =========================================================================
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          local opts = { buffer = true }

          -- Buffer settings
          vim.opt_local.autoread = true
          vim.opt_local.conceallevel = 2
          vim.opt_local.concealcursor = 'nc'

          -- Snacks image rendering (delayed for treesitter)
          vim.defer_fn(function()
            local ok, snacks = pcall(require, 'snacks')
            if ok and snacks.image and snacks.image.doc then
              snacks.image.doc._attach(vim.api.nvim_get_current_buf())
            end
          end, 100)

          -- Core keymaps
          apply_link_keymaps()

          -- Checkbox toggle
          vim.keymap.set('n', '<leader>ch', function()
            return require('obsidian').util.toggle_checkbox()
          end, vim.tbl_extend('force', opts, { desc = 'Toggle [Ch]eckbox' }))

          vim.keymap.set('n', '<leader>oc', function()
            return require('obsidian').util.toggle_checkbox()
          end, vim.tbl_extend('force', opts, { desc = '[O]bsidian Toggle [C]heckbox' }))

          vim.keymap.set('v', '<leader>oc', function()
            toggle_checkboxes_range(vim.fn.line 'v', vim.fn.line '.')
          end, vim.tbl_extend('force', opts, { desc = '[O]bsidian Toggle [C]heckbox (Visual)' }))

          -- Note operations
          vim.keymap.set('n', '<leader>on', ':Obsidian new<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [N]ew note' }))
          vim.keymap.set('n', '<leader>oo', ':Obsidian open<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [O]pen in app' }))
          vim.keymap.set('n', '<leader>of', ':Obsidian quick_switch<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [F]ind note' }))
          vim.keymap.set('n', '<leader>or', rename_note, vim.tbl_extend('force', opts, { desc = '[O]bsidian [R]ename' }))

          -- Search & navigation
          vim.keymap.set('n', '<leader>os', ':Obsidian search<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [S]earch' }))
          vim.keymap.set('n', '<leader>ob', ':Obsidian backlinks<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [B]acklinks' }))
          vim.keymap.set('n', '<leader>ol', ':Obsidian links<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [L]inks' }))
          vim.keymap.set('n', '<leader>ot', ':Obsidian tags<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [T]ags' }))
          vim.keymap.set('n', '<leader>oF', ':Obsidian follow_link<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [F]ollow link' }))
          vim.keymap.set('n', '<leader>ox', ':Obsidian toc<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian Table of Contents' }))

          -- Daily notes
          vim.keymap.set('n', '<leader>od', ':Obsidian today<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [D]aily note' }))
          vim.keymap.set('n', '<leader>oy', ':Obsidian yesterday<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [Y]esterday' }))
          vim.keymap.set('n', '<leader>om', ':Obsidian tomorrow<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian To[m]orrow' }))

          -- Workspace & utilities
          vim.keymap.set('n', '<leader>ow', ':Obsidian workspace<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian Switch [W]orkspace' }))
          vim.keymap.set('n', '<leader>oi', ':Obsidian paste_img<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian Paste [I]mage' }))

          -- Visual mode
          vim.keymap.set('v', '<leader>oe', ':Obsidian extract_note<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [E]xtract note' }))
          vim.keymap.set('v', '<leader>oL', ':Obsidian link<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [L]ink selection' }))
          vim.keymap.set('v', '<leader>oln', ':Obsidian link_new<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [L]ink [N]ew' }))
        end,
      })

      -- Re-assert the link keymaps after obsidian attaches: its own BufEnter
      -- handler installs a plain `<CR>` -> smart_action that would otherwise
      -- shadow the directory-link handling above.
      vim.api.nvim_create_autocmd('User', {
        pattern = 'ObsidianNoteEnter',
        callback = apply_link_keymaps,
        desc = 'Re-apply obsidian link keymaps after attach',
      })

      -- =========================================================================
      -- AUTO-RELOAD FOR EXTERNAL CHANGES
      -- =========================================================================
      vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
        pattern = '*.md',
        callback = function()
          if vim.fn.mode() ~= 'c' then
            vim.cmd 'checktime'
          end
        end,
        desc = 'Auto-reload markdown files when changed externally',
      })

      -- Re-fire the events this deferred setup missed, for every markdown
      -- buffer already open (a `nvim a.md b.md` / session-restore start loads
      -- several before setup runs).
      --
      -- Two events, in this order, both required:
      --   FileType  runs the settings/keymaps autocmd above, and obsidian's own
      --             FileType handler, which only *registers* per-buffer handlers.
      --   BufEnter  is where obsidian actually *attaches* — sets b:obsidian_buffer
      --             and 'includeexpr', and starts the obsidian-ls client that
      --             backs `Obsidian follow_link` / <CR>. Its BufEnter autocmd is
      --             created by the FileType handler above, so by the time it
      --             exists the buffer's own BufEnter has long since passed and
      --             nothing attaches until you leave the buffer and come back.
      --             Without this, links are dead on every buffer open at startup.
      vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'markdown' then
            vim.api.nvim_exec_autocmds('FileType', { buffer = buf, modeline = false })
            -- Scoped to obsidian's own augroup so re-entering the buffer doesn't
            -- replay every other plugin's BufEnter; fall back to an unscoped
            -- re-fire if upstream ever renames the group.
            local ok = pcall(vim.api.nvim_exec_autocmds, 'BufEnter', {
              buffer = buf,
              group = 'obsidian_setup',
              modeline = false,
            })
            if not ok then
              vim.api.nvim_exec_autocmds('BufEnter', { buffer = buf, modeline = false })
            end
          end
        end
      end)
    end,
  })
end

return M

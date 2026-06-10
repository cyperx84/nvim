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
      if lines[i]:match('^id:') then
        lines[i] = 'id: ' .. new_id
      elseif lines[i]:match('^title:') then
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

-- =============================================================================
-- PLUGIN SPECIFICATION
-- =============================================================================

M.specs = {
  {
    src = 'https://github.com/obsidian-nvim/obsidian.nvim',
    version = vim.version.range('*'),
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
      require('obsidian').setup({
        -- Workspaces
        -- Specific vaults come first so first-match resolution picks them for
        -- their own notes. 'notes' is a flexible catch-all: drop notes in any
        -- structure under ~/notes and obsidian manages frontmatter there, while
        -- leaving code repos, dotfiles, and ~/.config untouched. To relocate your
        -- notes later, just change this one path.
        workspaces = {
          { name = 'klaw', path = vim.fn.expand('~/.openclaw/workspace/vault') },
          { name = 'cyperx', path = vim.fn.expand('~/Library/Mobile Documents/iCloud~md~obsidian/Documents/cyperx') },
          { name = 'notes', path = vim.fn.expand('~/notes') },
        },

        -- Daily notes
        daily_notes = {
          folder = 'inbox',
          date_format = '%Y-%m-%d',
          alias_format = '%B %-d, %Y',
          default_tags = { 'daily-note' },
          template = 'daily.md',
        },

        -- Completion (served by the built-in obsidian-ls LSP server, surfaced
        -- through blink.cmp's `lsp` source; the old `completion.blink` opt is
        -- deprecated and stripped by the fork)
        completion = {
          min_chars = 2,
        },

        -- Note creation
        new_notes_location = 'current_dir',

        -- Templates
        templates = {
          folder = 'templates',
          date_format = '%Y-%m-%d',
          time_format = '%H:%M',
        },

        -- Note ID: URL-friendly slugs
        note_id_func = function(title)
          if title == nil or title == '' then
            return tostring(os.time())
          end
          return title:gsub('^%s*(.-)%s*$', '%1'):gsub('%s+', '-'):gsub('[^%w%-]', '')
        end,

        -- Frontmatter
        frontmatter = {
          -- Manage frontmatter for notes in any configured workspace (the two
          -- vaults plus anything under ~/notes). Markdown outside these — code
          -- repos, dotfiles, ~/.config — is never touched, since obsidian only
          -- activates inside a workspace.
          enabled = true,

          func = function(note)
            local now = os.date('%Y-%m-%d %H:%M')
            local out = {
              id = note.id,
              title = note.title or '',
              created = (note.metadata and note.metadata.created) or now,
              modified = now,
              reviewed = (note.metadata and note.metadata.reviewed) or nil,
              tags = note.tags or {},
              topics = (note.metadata and note.metadata.topics) or {},
              refs = (note.metadata and note.metadata.refs) or {},
              aliases = note.aliases or {},
              base = (note.metadata and note.metadata.base) or nil,
            }

            -- Preserve custom metadata fields
            if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
              local handled = { 'created', 'modified', 'reviewed', 'topics', 'refs', 'base' }
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
            return os.date('%Y-%m-%d-%H%M%S')
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
      })

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
          vim.keymap.set('n', 'gf', function()
            if vim.b.obsidian_buffer then
              vim.cmd('Obsidian follow_link')
            else
              vim.cmd('normal! gf')
            end
          end, { buffer = true, desc = 'Follow link under cursor' })
          vim.keymap.set('n', '<cr>', function()
            return require('obsidian').util.smart_action()
          end, { buffer = true, expr = true, desc = 'Smart action' })

          -- Checkbox toggle
          vim.keymap.set('n', '<leader>ch', function()
            return require('obsidian').util.toggle_checkbox()
          end, vim.tbl_extend('force', opts, { desc = 'Toggle [Ch]eckbox' }))

          vim.keymap.set('n', '<leader>oc', function()
            return require('obsidian').util.toggle_checkbox()
          end, vim.tbl_extend('force', opts, { desc = '[O]bsidian Toggle [C]heckbox' }))

          vim.keymap.set('v', '<leader>oc', function()
            toggle_checkboxes_range(vim.fn.line('v'), vim.fn.line('.'))
          end, vim.tbl_extend('force', opts, { desc = '[O]bsidian Toggle [C]heckbox (Visual)' }))

          -- Note operations
          vim.keymap.set('n', '<leader>on', ':Obsidian new<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [N]ew note' }))
          vim.keymap.set('n', '<leader>oo', ':Obsidian open<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [O]pen in app' }))
          vim.keymap.set('n', '<leader>of', ':Obsidian quick_switch<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian [F]ind note' }))
          vim.keymap.set('n', '<leader>or', rename_note, vim.tbl_extend('force', opts, { desc = '[O]bsidian [R]ename' }))

          -- Template operations
          vim.keymap.set('n', '<leader>oT', ':Obsidian new_from_template<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian New from [T]emplate' }))
          vim.keymap.set('n', '<leader>op', ':Obsidian template<CR>', vim.tbl_extend('force', opts, { desc = '[O]bsidian Insert tem[P]late' }))

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

      -- =========================================================================
      -- AUTO-RELOAD FOR EXTERNAL CHANGES
      -- =========================================================================
      vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
        pattern = '*.md',
        callback = function()
          if vim.fn.mode() ~= 'c' then
            vim.cmd('checktime')
          end
        end,
        desc = 'Auto-reload markdown files when changed externally',
      })

      -- Re-fire FileType for the triggering buffer so the markdown
      -- settings/keymaps autocmd above runs for it too.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          vim.api.nvim_exec_autocmds('FileType', { buffer = ev.buf, modeline = false })
        end
      end)
    end,
  })
end

return M

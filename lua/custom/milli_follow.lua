-- Animate a milli splash on the snacks dashboard, re-locating the header on
-- every reflow so the art follows the window when it resizes (e.g. opening a
-- vertical split like Claude Code). milli's built-in snacks() locates the
-- header once and never moves it, so a resize strands the animation while the
-- rest of the dashboard re-centers.

local M = {}

local ns = vim.api.nvim_create_namespace("milli_follow")

function M.attach(splash_name)
  local ok, data = pcall(require("milli.runtime").load, { splash = splash_name })
  if not ok or not data or not data.frames then return end

  -- Per-(fg,bg) highlight groups, created lazily. A colorscheme reload wipes
  -- them, so reset the cache when that happens.
  local hl = {}
  vim.api.nvim_create_autocmd("ColorScheme", { callback = function() hl = {} end })
  local function group(fg, bg)
    local key = fg .. bg
    if not hl[key] then
      local name = "MilliFollow_" .. fg:sub(2) .. "_" .. (bg == "NONE" and "0" or bg:sub(2))
      vim.api.nvim_set_hl(0, name, bg == "NONE" and { fg = fg } or { fg = fg, bg = bg })
      hl[key] = name
    end
    return hl[key]
  end

  -- Anchor = first non-blank line of frame 1; used to find where snacks placed
  -- the header after each (re)render.
  local anchor_row, anchor_text
  for i, line in ipairs(data.frames[1]) do
    if line:find("%S") then
      anchor_row, anchor_text = i, (line:gsub("%s+$", ""))
      break
    end
  end
  if not anchor_row then return end

  local function locate(buf)
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      local col = line:find(anchor_text, 1, true)
      if col then return i - anchor_row, line:sub(1, col - 1) end
    end
  end

  local function paint(buf, st)
    local frame = data.frames[st.idx + 1]
    if not frame then return end
    local lines = {}
    for i, line in ipairs(frame) do lines[i] = st.pad .. line end
    vim.bo[buf].modifiable = true
    pcall(vim.api.nvim_buf_set_lines, buf, st.row, st.row + #lines, false, lines)
    vim.bo[buf].modified = false
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, st.row, st.row + #lines)
    local colors = data.colors and data.colors[st.idx + 1]
    if not colors then return end
    for i, runs in ipairs(colors) do
      for _, run in ipairs(runs) do
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, st.row + i - 1, #st.pad + run[1], {
          end_col = #st.pad + run[2], hl_group = group(run[3], run[4]), priority = 200,
        })
      end
    end
  end

  local active = {} -- buf -> state; also the "already animating" guard

  local function animate(buf)
    if vim.bo[buf].filetype ~= "snacks_dashboard" then return end
    local row, pad = locate(buf)
    if not row then return end
    if active[buf] then -- already running: just follow the reflowed header
      active[buf].row, active[buf].pad = row, pad
      return
    end
    local st = { row = row, pad = pad, idx = 0 }
    active[buf] = st
    vim.api.nvim_buf_attach(buf, false, { on_detach = function() active[buf] = nil end })
    local function tick()
      if active[buf] ~= st or not vim.api.nvim_buf_is_valid(buf)
        or vim.bo[buf].filetype ~= "snacks_dashboard" then
        return
      end
      paint(buf, st)
      st.idx = (st.idx + 1) % #data.frames
      vim.defer_fn(tick, data.delays[st.idx + 1] or 100)
    end
    tick()
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = { "SnacksDashboardOpened", "SnacksDashboardUpdatePost" },
    callback = function()
      vim.schedule(function() animate(vim.api.nvim_get_current_buf()) end)
    end,
  })
end

return M

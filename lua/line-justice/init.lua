-- line-justice.nvim — dual absolute/relative line numbers via statuscol.nvim
--
-- Highlight resolution priority (highest → lowest):
--   1. User-provided colours in setup() opts
--   2. Named preset  (opts.line_numbers.preset)
--   3. Auto-detected from the active colorscheme's built-in highlight groups
--   4. Hardcoded fallback defaults

-- ---------------------------------------------------------------------------
-- LuaDoc types
-- ---------------------------------------------------------------------------

---Colour overrides for each part of the line-number gutter.
---Every key is optional — omit it to fall through to the preset or
---auto-detect.  Values are vim.api.nvim_set_hl-compatible tables, e.g.
---  { fg = "#bb9af7", bold = true }
---
---@class LineJusticeTheme
---@field CursorLine?     table  The line the cursor is on
---@field AbsoluteAbove?  table  Absolute numbers on lines above the cursor
---@field AbsoluteBelow?  table  Absolute numbers on lines below the cursor
---@field RelativeAbove?  table  Relative distance for lines above the cursor
---@field RelativeBelow?  table  Relative distance for lines below the cursor
---@field WrappedLine?    table  The ↳ indicator shown on soft-wrapped continuations

---Settings for the line-number columns.
---
---@class LineJusticeLineNumbers
---@field preset?  string            Named colour preset. "Horizon" uses the
---                                  built-in palette. nil = auto-detect from
---                                  the active colorscheme (default).
---@field theme?   LineJusticeTheme  Per-key colour overrides merged on top of
---                                  the preset / auto-detect result.

---Top-level configuration passed to setup().
---All keys are optional; omitted keys use the defaults.
---
---@class LineJusticeConfig
---@field line_numbers? LineJusticeLineNumbers

-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------

---@type LineJusticeConfig
local defaults = {
  line_numbers = {
    -- preset = nil,  -- set to "Horizon" to pin the built-in colour palette
    theme = {},       -- no overrides by default; everything comes from the
                      -- preset or is auto-detected from your colorscheme
  },
}

-- Internal options never exposed to the user
local INTERNAL = {
  -- Buffer types where line-justice is always disabled.
  -- "nofile" covers virtually all plugin-managed buffers (file trees,
  -- dashboards, pickers, scratch buffers, etc.)
  bt_ignore = { "nofile" },
  -- Right-align the cursor-line number in the relative column
  relculright = true,
}

---@type LineJusticeConfig
local config = {}

local M = {}

-- ---------------------------------------------------------------------------
-- Built-in colour presets
-- ---------------------------------------------------------------------------

-- "Horizon"
--   Inspired by a crisp horizon: cool blue-purple sky above the cursor,
--   fresh green earth below.  These are the author's original hand-crafted
--   colours, tuned for TokyoNight-family colorschemes but usable on any
--   dark theme.
--
--   CursorLine    #bb9af7  soft violet, bold
--   AbsoluteAbove #565f89  muted blue-grey
--   AbsoluteBelow #41664f  deep forest green
--   RelativeAbove #7b9ac7  brighter steel blue
--   RelativeBelow #6aa781  brighter sage green
--   WrappedLine   #565f89  same blue-grey as AbsoluteAbove, italic
--
---@type table<string, LineJusticeTheme>
local PRESETS = {
  Horizon = {
    CursorLine    = { fg = "#bb9af7", bold   = true  },
    AbsoluteAbove = { fg = "#565f89" },
    AbsoluteBelow = { fg = "#41664f" },
    RelativeAbove = { fg = "#7b9ac7" },
    RelativeBelow = { fg = "#6aa781" },
    WrappedLine   = { fg = "#565f89", italic = true  },
  },
}

-- ---------------------------------------------------------------------------
-- Fallback defaults
-- ---------------------------------------------------------------------------

-- Used only when auto-detect yields nothing AND no preset is active.
-- Mirrors the Horizon palette so there is always something sensible.
---@type LineJusticeTheme
local FALLBACK = {
  CursorLine    = { fg = "#bb9af7", bold   = true  },
  AbsoluteAbove = { fg = "#565f89" },
  AbsoluteBelow = { fg = "#41664f" },
  RelativeAbove = { fg = "#7b9ac7" },
  RelativeBelow = { fg = "#6aa781" },
  WrappedLine   = { fg = "#565f89", italic = true  },
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---Format a line number with thousands separators.
---@param num number
---@return string  e.g. 1234 → "1,234"
local function format_line_number(num)
  local str = tostring(num)
  return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

---Convert a numeric colour value (from nvim_get_hl) to a hex string.
---@param num number  0–16777215
---@return string     e.g. "#7aa2f7"
local function numeric_to_hex(num)
  return string.format("#%06x", num)
end

-- ---------------------------------------------------------------------------
-- Highlight resolution
-- ---------------------------------------------------------------------------

---Resolve and register the LineJustice* NeoVim highlight groups.
---
--- Priority (highest → lowest):
---   1. user_theme  — keys from setup() opts.line_numbers.theme
---   2. preset      — keys from the named preset (e.g. "Horizon")
---   3. colorscheme — fg derived from NeoVim's own highlight groups
---   4. FALLBACK    — hardcoded last resort
---
---@param user_theme  LineJusticeTheme  Per-key user overrides (may be empty)
---@param preset_theme LineJusticeTheme Preset colours (may be empty)
local function resolve_highlights(user_theme, preset_theme)
  user_theme   = user_theme   or {}
  preset_theme = preset_theme or {}

  ---Try to read the fg of a NeoVim highlight group; return hex or nil.
  ---@param name string
  ---@return string|nil
  local function try_fg(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl and hl.fg then return numeric_to_hex(hl.fg) end
    return nil
  end

  ---Build the final hl table for one slot.
  --- 1. colorscheme auto-detect (first probe that returns a colour wins)
  --- 2. layer preset on top
  --- 3. layer user override on top
  --- 4. if still no fg, use FALLBACK
  ---@param key    string    Theme key, e.g. "CursorLine"
  ---@param probes string[]  NeoVim hl groups to probe for auto-detect
  ---@return table
  local function resolve(key, probes)
    local base = {}

    -- Step 1: colorscheme
    for _, name in ipairs(probes) do
      local fg = try_fg(name)
      if fg then base.fg = fg; break end
    end

    -- Step 2: preset
    if preset_theme[key] then
      base = vim.tbl_deep_extend("force", base, preset_theme[key])
    end

    -- Step 3: user
    if user_theme[key] then
      base = vim.tbl_deep_extend("force", base, user_theme[key])
    end

    -- Step 4: fallback
    if not base.fg then
      base = vim.tbl_deep_extend("force", base, FALLBACK[key] or {})
    end

    return base
  end

  local r = {
    CursorLine    = resolve("CursorLine",    { "CursorLineNr" }),
    AbsoluteAbove = resolve("AbsoluteAbove", { "LineNr" }),
    AbsoluteBelow = resolve("AbsoluteBelow", { "LineNrAbove", "Comment" }),
    RelativeAbove = resolve("RelativeAbove", { "LineNr" }),
    RelativeBelow = resolve("RelativeBelow", { "LineNrBelow", "String" }),
    WrappedLine   = resolve("WrappedLine",   { "NonText" }),
  }

  vim.api.nvim_set_hl(0, "LineJusticeCursorLine",    r.CursorLine)
  vim.api.nvim_set_hl(0, "LineJusticeAbsoluteAbove", r.AbsoluteAbove)
  vim.api.nvim_set_hl(0, "LineJusticeAbsoluteBelow", r.AbsoluteBelow)
  vim.api.nvim_set_hl(0, "LineJusticeRelativeAbove", r.RelativeAbove)
  vim.api.nvim_set_hl(0, "LineJusticeRelativeBelow", r.RelativeBelow)
  vim.api.nvim_set_hl(0, "LineJusticeWrappedLine",   r.WrappedLine)
end

-- ---------------------------------------------------------------------------
-- statuscol wiring (internal — users never touch this directly)
-- ---------------------------------------------------------------------------

---@private
function M._setup_statuscol()
  local ok, statuscol = pcall(require, "statuscol")
  if not ok then
    vim.notify(
      "[line-justice] statuscol.nvim not found. "
        .. "Install luukvbaal/statuscol.nvim to use this feature.",
      vim.log.levels.WARN
    )
    return
  end

  local cfg = config.line_numbers

  -- Resolve preset
  local preset_theme = {}
  if cfg.preset then
    preset_theme = PRESETS[cfg.preset]
    if not preset_theme then
      vim.notify(
        "[line-justice] Unknown preset '" .. cfg.preset .. "'. "
          .. "Available presets: " .. table.concat(vim.tbl_keys(PRESETS), ", "),
        vim.log.levels.WARN
      )
      preset_theme = {}
    end
  end

  -- Initial highlight setup
  resolve_highlights(cfg.theme, preset_theme)

  -- Re-resolve whenever the colorscheme changes
  local grp = vim.api.nvim_create_augroup("LineJusticeColorScheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = grp,
    callback = function() resolve_highlights(cfg.theme, preset_theme) end,
  })

  statuscol.setup({
    relculright = INTERNAL.relculright,
    bt_ignore   = INTERNAL.bt_ignore,
    segments = {
      {
        text = {
          function(args)
            if args.virtnum == 0 then
              -- ── Absolute line number highlight ────────────────────────────
              local abs_hl
              if args.relnum == 0 then
                abs_hl = "%#LineJusticeCursorLine#"
              elseif args.lnum > vim.fn.line(".") then
                abs_hl = "%#LineJusticeAbsoluteBelow#"
              else
                abs_hl = "%#LineJusticeAbsoluteAbove#"
              end

              -- ── Relative line number highlight ────────────────────────────
              local rel_hl
              if args.relnum == 0 then
                rel_hl = "%#LineJusticeCursorLine#"
              elseif args.lnum > vim.fn.line(".") then
                rel_hl = "%#LineJusticeRelativeBelow#"
              else
                rel_hl = "%#LineJusticeRelativeAbove#"
              end

              -- ── Format both numbers ───────────────────────────────────────
              local abs_num = format_line_number(args.lnum)
              -- Cursor line: blank relative column (never show "0")
              local rel_num = args.relnum == 0 and "" or format_line_number(args.relnum)

              -- ── Fixed-width columns (accounts for comma separators) ───────
              local total_lines = vim.fn.line("$")
              local num_digits  = #tostring(total_lines)
              local num_commas  = math.floor((num_digits - 1) / 3)
              local col_w       = num_digits + num_commas

              -- Right-align absolute number
              abs_num = string.rep(" ", math.max(0, col_w - #abs_num)) .. abs_num

              -- Pad relative number so total gutter width stays fixed
              local target_w  = col_w + 1 + col_w
              local current_w = #abs_num + 1 + #rel_num
              local rel_pad   = string.rep(" ", math.max(0, target_w - current_w))

              return abs_hl .. abs_num .. " " .. rel_hl .. rel_num .. rel_pad
            else
              return "%#LineJusticeWrappedLine#↳ "
            end
          end,
        },
        click = "v:lua.ScLa",
      },
    },
  })
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Initialise line-justice.nvim.
---
--- Minimal — use all defaults (colours auto-detected from your colorscheme):
---
---   require("line-justice").setup()
---
--- Use the built-in Horizon colour preset:
---
---   require("line-justice").setup({
---     line_numbers = {
---       preset = "Horizon",
---     },
---   })
---
--- Horizon preset with one colour overridden:
---
---   require("line-justice").setup({
---     line_numbers = {
---       preset = "Horizon",
---       theme = {
---         CursorLine = { fg = "#ff9e64", bold = true },
---       },
---     },
---   })
---
--- Fully manual colours (no preset, no auto-detect):
---
---   require("line-justice").setup({
---     line_numbers = {
---       theme = {
---         CursorLine    = { fg = "#bb9af7", bold = true },
---         AbsoluteAbove = { fg = "#565f89" },
---         AbsoluteBelow = { fg = "#41664f" },
---         RelativeAbove = { fg = "#7b9ac7" },
---         RelativeBelow = { fg = "#6aa781" },
---         WrappedLine   = { fg = "#565f89", italic = true },
---       },
---     },
---   })
---
---@param opts? LineJusticeConfig  Partial config; deep-merged with defaults
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})
  M._setup_statuscol()
end

---Return the current resolved configuration.
---@return LineJusticeConfig
function M.get_config()
  return config
end

return M

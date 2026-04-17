-- line-justice.nvim — dual absolute/relative line numbers via statuscol.nvim
--
-- Displays both the absolute line number (true position in the file) and the
-- relative distance from the cursor on every line simultaneously. Makes pair
-- programming, code reviews, and remote collaboration effortless.
--
-- ┌─────────────────────────────────────────────────────────────────────┐
-- │  Configuration quick-reference                                      │
-- │                                                                     │
-- │  line_numbers.theme     string   Named palette ("Horizon" default)  │
-- │                         nil      Auto-detect from colorscheme       │
-- │  line_numbers.overrides table    Per-key colour overrides           │
-- │                                                                     │
-- │  Colour resolution priority (highest → lowest):                    │
-- │    1. line_numbers.overrides  (your per-key tweaks)                │
-- │    2. line_numbers.theme      (named built-in palette)             │
-- │    3. colorscheme auto-detect (NeoVim's own highlight groups)      │
-- │    4. Hardcoded fallback      (always something sensible)          │
-- └─────────────────────────────────────────────────────────────────────┘

-- ---------------------------------------------------------------------------
-- LuaDoc types
-- ---------------------------------------------------------------------------

---Per-key colour overrides for the line-number gutter.
---
--- Every key is optional. Any key you omit falls through to the named theme
--- or auto-detect. Values are vim.api.nvim_set_hl-compatible tables:
---   { fg = "#rrggbb" }
---   { fg = "#rrggbb", bold = true }
---   { fg = "#rrggbb", italic = true }
---
---@class LineJusticeOverrides
---@field CursorLine?     table  The line the cursor is currently on
---@field AbsoluteAbove?  table  Absolute line numbers on lines above the cursor
---@field AbsoluteBelow?  table  Absolute line numbers on lines below the cursor
---@field RelativeAbove?  table  Relative distance for lines above the cursor
---@field RelativeBelow?  table  Relative distance for lines below the cursor
---@field WrappedLine?    table  The ↳ indicator on soft-wrapped continuation lines

---Settings for the line-number columns.
---
---@class LineJusticeLineNumbers
---@field theme?     string                 Name of a built-in colour palette.
---                                         "Horizon" = cool blues above, greens below.
---                                         nil       = auto-detect from your colorscheme.
---@field overrides? LineJusticeOverrides   Per-key colour overrides applied on top of
---                                         the named theme or auto-detect result.
---                                         Any key left out falls through unchanged.

---Top-level configuration table passed to setup().
---All keys are optional — omitting them uses the defaults shown below.
---
---@class LineJusticeConfig
---@field line_numbers? LineJusticeLineNumbers

-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------

---@type LineJusticeConfig
local defaults = {
  line_numbers = {
    theme     = "Horizon", -- use the built-in Horizon palette by default
                           -- set to nil to auto-detect from your colorscheme
    overrides = {},        -- no overrides; all colours come from the theme
  },
}

-- Internal settings — deliberately not exposed to users.
-- These are implementation details of the statuscol.nvim integration.
local INTERNAL = {
  -- "nofile" buftype covers virtually all plugin-managed buffers:
  -- file trees, dashboards, pickers, scratch buffers, floating windows, etc.
  bt_ignore   = { "nofile" },
  -- Right-align the cursor-line number in the relative column
  relculright = true,
}

---@type LineJusticeConfig
local config = {}

local M = {}

-- ---------------------------------------------------------------------------
-- Built-in colour themes (palettes)
-- ---------------------------------------------------------------------------
--
-- Each entry in THEMES is a complete LineJusticeOverrides-compatible table.
-- Add more themes here in future; they become available immediately via
-- line_numbers.theme = "<name>".
--
-- ┌──────────────┬──────────┬────────────────────────────────────────────┐
-- │ Key          │ Hex      │ Description                                │
-- ├──────────────┼──────────┼────────────────────────────────────────────┤
-- │ CursorLine   │ #bb9af7  │ Soft violet, bold — stands out on cursor   │
-- │ AbsoluteAbove│ #565f89  │ Muted blue-grey — absolute nums above      │
-- │ AbsoluteBelow│ #41664f  │ Deep forest green — absolute nums below    │
-- │ RelativeAbove│ #7b9ac7  │ Brighter steel blue — relative nums above  │
-- │ RelativeBelow│ #6aa781  │ Brighter sage green — relative nums below  │
-- │ WrappedLine  │ #565f89  │ Same blue-grey as AbsoluteAbove, italic    │
-- └──────────────┴──────────┴────────────────────────────────────────────┘
--
---@type table<string, LineJusticeOverrides>
local THEMES = {
  -- "Horizon"
  -- Inspired by a crisp horizon line: cool blue-purple sky above the cursor,
  -- fresh green earth below. Original hand-crafted colours by the author,
  -- tuned for TokyoNight-family colorschemes but great on any dark theme.
  Horizon = {
    CursorLine    = { fg = "#bb9af7", bold   = true },
    AbsoluteAbove = { fg = "#565f89" },
    AbsoluteBelow = { fg = "#41664f" },
    RelativeAbove = { fg = "#7b9ac7" },
    RelativeBelow = { fg = "#6aa781" },
    WrappedLine   = { fg = "#565f89", italic = true },
  },
}

-- ---------------------------------------------------------------------------
-- Hardcoded fallback
-- ---------------------------------------------------------------------------
--
-- Only used when:
--   • line_numbers.theme is nil (auto-detect mode), AND
--   • the active colorscheme does not define the probed highlight group
--
-- Mirrors the Horizon palette so there is always a sensible colour even on
-- unknown or minimal colorschemes.
--
---@type LineJusticeOverrides
local FALLBACK = {
  CursorLine    = { fg = "#bb9af7", bold   = true },
  AbsoluteAbove = { fg = "#565f89" },
  AbsoluteBelow = { fg = "#41664f" },
  RelativeAbove = { fg = "#7b9ac7" },
  RelativeBelow = { fg = "#6aa781" },
  WrappedLine   = { fg = "#565f89", italic = true },
}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Format a line number with thousands separators.
---@param num number
---@return string  e.g. 1234 → "1,234"
local function format_line_number(num)
  local str = tostring(num)
  return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

---Convert a numeric colour value (as returned by nvim_get_hl) to hex.
---@param num number  Integer 0–16777215
---@return string     e.g. "#7aa2f7"
local function numeric_to_hex(num)
  return string.format("#%06x", num)
end

-- ---------------------------------------------------------------------------
-- Highlight resolution
-- ---------------------------------------------------------------------------

---Resolve and register all LineJustice* NeoVim highlight groups.
---
--- Called once at setup() and again whenever :colorscheme changes so that
--- colours always stay in sync with the active theme.
---
--- Resolution order for each colour slot (highest priority first):
---
---   1. overrides  — the user's per-key table from line_numbers.overrides
---   2. theme      — the named built-in palette from line_numbers.theme
---   3. colorscheme — fg derived from NeoVim's own highlight groups (probed
---                    in order; first non-nil result wins)
---   4. FALLBACK   — hardcoded last resort; always produces a colour
---
---@param overrides  LineJusticeOverrides  User per-key overrides (may be empty)
---@param theme_tbl  LineJusticeOverrides  Resolved theme table (may be empty)
local function resolve_highlights(overrides, theme_tbl)
  overrides  = overrides  or {}
  theme_tbl  = theme_tbl  or {}

  ---Attempt to read the `fg` of a NeoVim highlight group.
  ---Returns the hex string, or nil if the group has no fg.
  ---@param name string
  ---@return string|nil
  local function try_fg(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl and hl.fg then return numeric_to_hex(hl.fg) end
    return nil
  end

  ---Build the final highlight table for one colour slot.
  ---
  --- Steps:
  ---   1. Try each probe group in order; use the first fg found (colorscheme)
  ---   2. Layer the theme value on top (theme wins over colorscheme)
  ---   3. Layer the user override on top (override wins over everything)
  ---   4. If still no fg at all, use the hardcoded FALLBACK
  ---
  ---@param key    string    Slot name, e.g. "CursorLine"
  ---@param probes string[]  NeoVim highlight groups to probe for auto-detect
  ---@return table           vim.api.nvim_set_hl-compatible table
  local function resolve(key, probes)
    local base = {}

    -- Step 1: colorscheme auto-detect
    for _, name in ipairs(probes) do
      local fg = try_fg(name)
      if fg then base.fg = fg; break end
    end

    -- Step 2: named theme (overrides colorscheme-derived fg)
    if theme_tbl[key] then
      base = vim.tbl_deep_extend("force", base, theme_tbl[key])
    end

    -- Step 3: user overrides (highest priority — overrides everything above)
    if overrides[key] then
      base = vim.tbl_deep_extend("force", base, overrides[key])
    end

    -- Step 4: fallback — ensure there is always a fg colour
    if not base.fg then
      base = vim.tbl_deep_extend("force", base, FALLBACK[key] or {})
    end

    return base
  end

  -- Resolve every slot. The probe lists define which NeoVim highlight groups
  -- are queried when auto-detecting from the colorscheme.
  local r = {
    CursorLine    = resolve("CursorLine",    { "CursorLineNr" }),
    AbsoluteAbove = resolve("AbsoluteAbove", { "LineNr" }),
    AbsoluteBelow = resolve("AbsoluteBelow", { "LineNrAbove", "Comment" }),
    RelativeAbove = resolve("RelativeAbove", { "LineNr" }),
    RelativeBelow = resolve("RelativeBelow", { "LineNrBelow", "String" }),
    WrappedLine   = resolve("WrappedLine",   { "NonText" }),
  }

  -- Register the highlight groups used in the statuscolumn string
  vim.api.nvim_set_hl(0, "LineJusticeCursorLine",    r.CursorLine)
  vim.api.nvim_set_hl(0, "LineJusticeAbsoluteAbove", r.AbsoluteAbove)
  vim.api.nvim_set_hl(0, "LineJusticeAbsoluteBelow", r.AbsoluteBelow)
  vim.api.nvim_set_hl(0, "LineJusticeRelativeAbove", r.RelativeAbove)
  vim.api.nvim_set_hl(0, "LineJusticeRelativeBelow", r.RelativeBelow)
  vim.api.nvim_set_hl(0, "LineJusticeWrappedLine",   r.WrappedLine)
end

-- ---------------------------------------------------------------------------
-- statuscol wiring (internal — users configure line-justice, not statuscol)
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

  -- Resolve the named theme into a concrete colour table
  local theme_tbl = {}
  if cfg.theme then
    theme_tbl = THEMES[cfg.theme]
    if not theme_tbl then
      vim.notify(
        "[line-justice] Unknown theme '" .. cfg.theme .. "'. "
          .. "Available themes: " .. table.concat(vim.tbl_keys(THEMES), ", "),
        vim.log.levels.WARN
      )
      theme_tbl = {}
    end
  end

  -- Perform initial highlight resolution
  resolve_highlights(cfg.overrides, theme_tbl)

  -- Re-resolve whenever the user switches colorscheme so colours stay in sync.
  -- Both the theme and overrides are always re-applied on top of the new scheme.
  local grp = vim.api.nvim_create_augroup("LineJusticeColorScheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = grp,
    callback = function() resolve_highlights(cfg.overrides, theme_tbl) end,
  })

  -- Wire up the statuscol.nvim segment
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
              -- Cursor line: leave the relative column blank (never show "0")
              local rel_num = args.relnum == 0 and "" or format_line_number(args.relnum)

              -- ── Fixed-width columns (accounts for thousands-separator commas)
              local total_lines = vim.fn.line("$")
              local num_digits  = #tostring(total_lines)
              local num_commas  = math.floor((num_digits - 1) / 3)
              local col_w       = num_digits + num_commas

              -- Right-align the absolute number
              abs_num = string.rep(" ", math.max(0, col_w - #abs_num)) .. abs_num

              -- Pad the relative number so the total gutter width stays fixed
              local target_w  = col_w + 1 + col_w
              local current_w = #abs_num + 1 + #rel_num
              local rel_pad   = string.rep(" ", math.max(0, target_w - current_w))

              return abs_hl .. abs_num .. " " .. rel_hl .. rel_num .. rel_pad
            else
              -- Soft-wrapped continuation lines
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
--- ── The simplest setup ───────────────────────────────────────────────────
---
--- Uses the Horizon theme (the default):
---
---   require("line-justice").setup()
---
--- ── Using a named theme ──────────────────────────────────────────────────
---
--- "Horizon" is the only built-in theme. Cool blue-purple sky above the
--- cursor, fresh green earth below:
---
---   require("line-justice").setup({
---     line_numbers = {
---       theme = "Horizon",
---     },
---   })
---
--- ── Auto-detect from your colorscheme ────────────────────────────────────
---
--- Set theme = nil to derive colours from NeoVim's own highlight groups.
--- Colours update automatically whenever you run :colorscheme:
---
---   require("line-justice").setup({
---     line_numbers = {
---       theme = nil,
---     },
---   })
---
--- ── Overriding individual colours on top of a theme ──────────────────────
---
--- Use overrides to tweak one or two colours while keeping the rest of the
--- theme intact. Any key you omit stays exactly as the theme defines it:
---
---   require("line-justice").setup({
---     line_numbers = {
---       theme = "Horizon",
---       overrides = {
---         CursorLine = { fg = "#ff9e64", bold = true }, -- swap cursor colour
---       },
---     },
---   })
---
--- ── Overriding colours on top of auto-detect ─────────────────────────────
---
--- overrides works the same way when theme = nil. The auto-detected colour
--- is used as the base, then your override is layered on top:
---
---   require("line-justice").setup({
---     line_numbers = {
---       theme = nil,
---       overrides = {
---         AbsoluteAbove = { fg = "#7aa2f7" },
---         RelativeBelow = { fg = "#9ece6a" },
---       },
---     },
---   })
---
--- ── Fully manual colours ─────────────────────────────────────────────────
---
--- Set theme = nil and provide all six keys in overrides to take complete
--- control. Auto-detect is skipped for any key you supply:
---
---   require("line-justice").setup({
---     line_numbers = {
---       theme = nil,
---       overrides = {
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

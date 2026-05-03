-- line-justice.nvim — dual absolute/relative line numbers
--
-- Displays both the absolute line number (true position in the file) and the
-- relative distance from the cursor on every line simultaneously. Makes pair
-- programming, code reviews, and remote collaboration effortless.
--
-- line-justice is a statuscol.nvim segment provider. It owns:
--   • colour themes and highlight group registration
--   • dual abs/rel number formatting and rendering
--   • soft-wrapped continuation-line indicators
--
-- It does NOT call statuscol.setup(). You wire it in yourself:
--
--   require("statuscol").setup({
--     segments = {
--       { text = { require("line-justice").segment }, click = "v:lua.ScLa" },
--     },
--   })
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  Configuration quick-reference                                           │
-- │                                                                          │
-- │  line_numbers.theme       string   Named palette ("Horizon" default)     │
-- │                           nil      Auto-detect from colorscheme          │
-- │  line_numbers.overrides   table    Per-key colour overrides              │
-- │                                                                          │
-- │  wrapped_lines.indicator  string   Named indicator preset (default:      │
-- │                                    "Bar" — a line extending down to all  │
-- │                                    overlapping lines)                    │
-- │  wrapped_lines.custom     string   Character used when indicator="Custom"│
-- │                                                                          │
-- │  Colour resolution priority (highest → lowest):                         │
-- │    1. line_numbers.overrides  (your per-key tweaks)                     │
-- │    2. line_numbers.theme      (named built-in palette)                  │
-- │    3. colorscheme auto-detect (NeoVim's own highlight groups)           │
-- │    4. Hardcoded fallback      (always something sensible)               │
-- │                                                                          │
-- │  Theme management:                                                       │
-- │    require("line-justice").themes.register(spec)  register custom theme  │
-- │    require("line-justice").themes.list()           list all themes        │
-- │    require("line-justice").themes.exists(name)     check if theme exists  │
-- │    require("line-justice").themes.get(name)        get theme colors table │
-- │                                                                          │
-- │  Segment access:                                                         │
-- │    require("line-justice").segment   the statuscol segment function      │
-- └──────────────────────────────────────────────────────────────────────────┘

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
---@field WrappedLine?    table  Colour of the wrapped-line indicator character


---Distance-based colour fade for line numbers.
---
--- When enabled, line numbers progressively desaturate toward grey as their
--- distance from the cursor increases. Relative numbers fade more aggressively
--- than absolute numbers because they *are* the distance signal — a "3" should
--- shout, an "87" should whisper.
---
--- Relative numbers use 4 tiers (Near → Mid → Far → Distant).
--- Absolute numbers use 2 tiers (Near → Distant) for a subtler effect.
---
---@class LineJusticeFade
---@field enabled?           boolean  Enable distance-based fading (default: true).
---@field bands?             table    Distance thresholds: { near=5, mid=15, far=30 }.
---                                   Lines within `near` rows → full colour.
---                                   Lines within `mid`  rows → light fade.
---                                   Lines within `far`  rows → stronger fade.
---                                   Lines beyond `far`  rows → maximum fade.
---@field relative_strength? number   Max fade for relative numbers, 0.0–1.0 (default: 0.75).
---                                   0.0 = no fade. 1.0 = fully desaturated grey.
---@field absolute_strength? number   Max fade for absolute numbers, 0.0–1.0 (default: 0.30).
---                                   Kept lower so absolute numbers stay readable as
---                                   reference points at any distance.


---Settings for the line-number columns.
---
---@class LineJusticeLineNumbers
---@field theme?     string                Name of a built-in or registered colour palette.
---                                        "Horizon"  = cool blues above, greens below (default).
---                                        "Dawn"     = warm amber and rose tones.
---                                        "Midnight" = cool monochrome blue-greys.
---                                        nil        = auto-detect from your colorscheme.
---@field overrides? LineJusticeOverrides  Per-key colour overrides applied on top of
---                                        the named theme or auto-detect result.
---                                        Any key left out falls through unchanged.
---@field fade?      LineJusticeFade       Distance-based colour fade settings.


---Settings for soft-wrapped continuation lines.
---
--- When a line is too long for the window and wraps, NeoVim renders the
--- continuation as a virtual line. line-justice can show an indicator
--- character in the gutter of those virtual lines, centred in the gutter
--- width, to visually distinguish them from real lines.
---
---@class LineJusticeWrappedLines
---@field indicator? string  Named indicator preset. One of:
---                          "None"     — blank gutter, no character (default)
---                          "Arrow"    — ↳  classic turn-down arrow
---                          "Chevron"  — ›  single right-pointing chevron
---                          "Dot"      — ·  middle dot / interpunct
---                          "Ellipsis" — …  horizontal ellipsis
---                          "Bar"      — │  thin vertical bar
---                          "Custom"   — use the string in wrapped_lines.custom
---@field custom?    string  The character (or short string) to display when
---                          indicator = "Custom". Ignored for all other presets.
---                          Examples: "»", "⤷", "▸", "→", "╰"

---Top-level configuration table passed to setup().
---All keys are optional — omitting them uses the defaults shown below.
---
---@class LineJusticeConfig
---@field line_numbers?  LineJusticeLineNumbers
---@field wrapped_lines? LineJusticeWrappedLines

-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------

---@type LineJusticeConfig
local defaults = {
  line_numbers = {
    theme     = "Horizon", -- use the built-in Horizon palette by default
                           -- set to nil to auto-detect from your colorscheme
    overrides = {},        -- no overrides; all colours come from the theme
    fade = {
      enabled            = true,  -- progressively desaturate distant line numbers
      bands              = { near = 5, mid = 15, far = 30 },
      relative_strength  = 0.75,  -- relative numbers fade strongly (they ARE the distance signal)
      absolute_strength  = 0.30,  -- absolute numbers fade subtly (reference points stay readable)
    },
  },
  wrapped_lines = {
    indicator = "Bar",    -- vertical bar on wrapped continuation lines
    custom    = "",        -- only used when indicator = "Custom"
  },
}

---@type LineJusticeConfig
local config = {}

local M = {}

-- ---------------------------------------------------------------------------
-- Mutable render state
-- ---------------------------------------------------------------------------
--
-- The segment function is built ONCE at module load time and never replaced.
-- It closes over _state, which setup() mutates on every call.
--
-- This means:
--   • M.segment is never nil — statuscol can capture it before setup() runs
--   • re-setup() works transparently — no need to re-wire statuscol
--   • the captured reference in statuscol always delegates to current config
--
-- _state.indicator_char is the only field needed at render time that isn't
-- already handled by the LineJustice* highlight groups registered via
-- nvim_set_hl. Colours are updated in place by resolve_highlights() and
-- picked up automatically by the highlight group name strings in the segment.
--
---@class LineJusticeState
---@field indicator_char string   Pre-resolved wrapped-line indicator character
---@field ready          boolean  True once setup() has been called at least once
---@field fade_enabled   boolean  True when distance-based fading is active
---@field fade_bands     table    Distance thresholds: { near, mid, far }

---@type LineJusticeState
local _state = {
  indicator_char = "",
  ready          = false,
  fade_enabled   = false,
  fade_bands     = { near = 5, mid = 15, far = 30 },
}

-- Ensures the "segment called before setup()" ERROR fires at most once,
-- regardless of how many lines statuscol renders before setup() completes.
local _warned_not_ready = false

-- ---------------------------------------------------------------------------
-- Theme registry (public sub-module)
-- ---------------------------------------------------------------------------
--
-- Exposed as require("line-justice").themes so that developers can register
-- custom themes before or after calling setup().
--
-- See lua/line-justice/themes/init.lua for the full registry API.
--
M.themes = require("line-justice.themes")

-- ---------------------------------------------------------------------------
-- Built-in wrapped-line indicator presets
-- ---------------------------------------------------------------------------
--
-- Each value is the exact character rendered in the gutter.
-- "None" is the empty string — the gutter is left blank.
--
-- ┌───────────┬─────┬─────────────────────────────────────────────────────┐
-- │ Name      │ Chr │ Description                                         │
-- ├───────────┼─────┼─────────────────────────────────────────────────────┤
-- │ None      │     │ Blank — no character shown (default)                │
-- │ Arrow     │  ↳  │ Turn-down arrow — classic "continued from above"    │
-- │ Chevron   │  ›  │ Single right chevron — lightweight directional hint │
-- │ Dot       │  ·  │ Middle dot / interpunct — subtle, minimal           │
-- │ Ellipsis  │  …  │ Horizontal ellipsis — "more content continues"      │
-- │ Bar       │  │  │ Thin vertical bar — structural / tree-style         │
-- │ Custom    │ any │ Whatever string you set in wrapped_lines.custom      │
-- └───────────┴─────┴─────────────────────────────────────────────────────┘
--
---@type table<string, string>
local WRAPPED_INDICATORS = {
  None     = "",
  Arrow    = "↳",
  Chevron  = "›",
  Dot      = "·",
  Ellipsis = "…",
  Bar      = "│",
  -- "Custom" is handled separately — its value comes from wrapped_lines.custom
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
  CursorLine    = { fg = "#FF966C", bold   = true },
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
  return (str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

---Convert a numeric colour value (as returned by nvim_get_hl) to hex.
---@param num number  Integer 0–16777215
---@return string     e.g. "#7aa2f7"
local function numeric_to_hex(num)
  return string.format("#%06x", num)
end

---Resolve the wrapped-line indicator character from config.
---
--- Returns the character to render (may be empty string for "None").
--- Validates the indicator name and falls back to "" with a warning if
--- the name is unrecognised and indicator != "Custom".
---
---@param  wl_cfg LineJusticeWrappedLines
---@return string  The indicator character (may be empty)
local function resolve_indicator(wl_cfg)
  local name = wl_cfg.indicator or "Bar"

  if name == "Custom" then
    -- Use whatever the user put in wrapped_lines.custom
    local ch = wl_cfg.custom or ""
    if ch == "" then
      vim.notify(
        "[line-justice] wrapped_lines.indicator = \"Custom\" but "
          .. "wrapped_lines.custom is empty. Showing blank gutter.",
        vim.log.levels.WARN
      )
    end
    return ch
  end

  local ch = WRAPPED_INDICATORS[name]
  if ch == nil then
    vim.notify(
      "[line-justice] Unknown wrapped_lines.indicator '"
        .. name .. "'. "
        .. "Available: "
        .. table.concat(vim.tbl_keys(WRAPPED_INDICATORS), ", ")
        .. ", Custom. Falling back to \"Bar\".",
      vim.log.levels.WARN
    )
    return ""
  end

  return ch
end

---Centre a string inside a field of given width.
--- If the string is wider than the field it is returned as-is.
---@param str   string
---@param width number  Total field width in characters
---@return string
local function centre(str, width)
  local pad = width - #str
  if pad <= 0 then return str end
  local left  = math.floor(pad / 2)
  local right = pad - left
  return string.rep(" ", left) .. str .. string.rep(" ", right)
end

---Interpolate a hex colour toward its own luminance grey by `strength`.
---
--- Desaturating toward grey (rather than simply darkening) works on both
--- dark and light themes: the perceived brightness stays roughly constant
--- while the hue fades away, making distant numbers recede without
--- disappearing entirely.
---
---@param hex      string  Source colour, e.g. "#7b9ac7"
---@param strength number  0.0 = original colour, 1.0 = fully grey
---@return string          Interpolated hex colour
local function fade_colour(hex, strength)
  if strength <= 0 then return hex end
  -- Parse the three channels
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  if not (r and g and b) then return hex end
  -- Luminance-weighted grey target (ITU-R BT.601)
  local grey = math.floor(0.299 * r + 0.587 * g + 0.114 * b)
  if strength >= 1 then
    return string.format("#%02x%02x%02x", grey, grey, grey)
  end
  -- Linear interpolation toward grey
  local nr = math.floor(r + (grey - r) * strength)
  local ng = math.floor(g + (grey - g) * strength)
  local nb = math.floor(b + (grey - b) * strength)
  return string.format("#%02x%02x%02x", nr, ng, nb)
end

---Map a relative line distance to one of four fade tiers for relative numbers.
--- Takes the absolute value of relnum so lines above the cursor (where
--- args.relnum is negative) are handled identically to lines below.
---@param relnum number  args.relnum (negative above cursor, positive below)
---@param bands  table   { near, mid, far } thresholds
---@return string        "Near" | "Mid" | "Far" | "Distant"
local function get_rel_tier(relnum, bands)
  relnum = math.abs(relnum)
  if relnum <= bands.near then return "Near"
  elseif relnum <= bands.mid  then return "Mid"
  elseif relnum <= bands.far  then return "Far"
  else return "Distant" end
end

---Map a relative line distance to one of two fade tiers for absolute numbers.
--- Absolute numbers use only two tiers (Near / Distant) for a subtler effect.
--- Takes the absolute value of relnum so lines above the cursor (where
--- args.relnum is negative) are handled identically to lines below.
---@param relnum number  args.relnum (negative above cursor, positive below)
---@param bands  table   { near, mid, far } thresholds
---@return string        "Near" | "Distant"
local function get_abs_tier(relnum, bands)
  relnum = math.abs(relnum)
  if relnum <= bands.far then return "Near"
  else return "Distant" end
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
---@param fade_cfg   LineJusticeFade|nil   Fade config; nil or disabled = no banded groups
local function resolve_highlights(overrides, theme_tbl, fade_cfg)
  overrides = overrides or {}
  theme_tbl = theme_tbl or {}

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

  -- Register the flat highlight groups (always present; used when fade is off
  -- and for the cursor line which is never faded).
  vim.api.nvim_set_hl(0, "LineJusticeCursorLine",    r.CursorLine)
  vim.api.nvim_set_hl(0, "LineJusticeAbsoluteAbove", r.AbsoluteAbove)
  vim.api.nvim_set_hl(0, "LineJusticeAbsoluteBelow", r.AbsoluteBelow)
  vim.api.nvim_set_hl(0, "LineJusticeRelativeAbove", r.RelativeAbove)
  vim.api.nvim_set_hl(0, "LineJusticeRelativeBelow", r.RelativeBelow)
  vim.api.nvim_set_hl(0, "LineJusticeWrappedLine",   r.WrappedLine)

  -- Register banded fade groups when fade is enabled.
  -- Relative numbers: 4 tiers (Near → Mid → Far → Distant).
  -- Absolute numbers: 2 tiers (Near → Distant) — subtler effect.
  if fade_cfg and fade_cfg.enabled ~= false then
    local rel_s = fade_cfg.relative_strength or 0.75
    local abs_s = fade_cfg.absolute_strength or 0.30

    -- Relative tiers: evenly distribute strength across 4 steps
    local rel_tiers = {
      Near    = 0.0,
      Mid     = rel_s * 0.33,
      Far     = rel_s * 0.66,
      Distant = rel_s,
    }
    for tier, strength in pairs(rel_tiers) do
      local hl_above = vim.tbl_deep_extend("force", {}, r.RelativeAbove)
      local hl_below = vim.tbl_deep_extend("force", {}, r.RelativeBelow)
      if hl_above.fg then hl_above.fg = fade_colour(hl_above.fg, strength) end
      if hl_below.fg then hl_below.fg = fade_colour(hl_below.fg, strength) end
      vim.api.nvim_set_hl(0, "LineJusticeRelativeAbove" .. tier, hl_above)
      vim.api.nvim_set_hl(0, "LineJusticeRelativeBelow" .. tier, hl_below)
    end

    -- Absolute tiers: only Near (full colour) and Distant (faded)
    local abs_tiers = { Near = 0.0, Distant = abs_s }
    for tier, strength in pairs(abs_tiers) do
      local hl_above = vim.tbl_deep_extend("force", {}, r.AbsoluteAbove)
      local hl_below = vim.tbl_deep_extend("force", {}, r.AbsoluteBelow)
      if hl_above.fg then hl_above.fg = fade_colour(hl_above.fg, strength) end
      if hl_below.fg then hl_below.fg = fade_colour(hl_below.fg, strength) end
      vim.api.nvim_set_hl(0, "LineJusticeAbsoluteAbove" .. tier, hl_above)
      vim.api.nvim_set_hl(0, "LineJusticeAbsoluteBelow" .. tier, hl_below)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Segment (built once at module load, closes over _state)
-- ---------------------------------------------------------------------------
--
-- The segment function is assigned here — at module load — so M.segment is
-- never nil. It reads _state at render time, so every setup() call takes
-- effect immediately without statuscol needing to be re-wired.
--
-- Before setup() has been called, _state.ready is false. The function emits
-- a one-shot ERROR and returns an empty string so the gutter is blank but
-- the misconfiguration is impossible to miss.
--
---@type fun(args: table): string
local function _segment(args)
  if not _state.ready then
    if not _warned_not_ready then
      _warned_not_ready = true
      vim.notify(
        "[line-justice] segment called before setup(). "
          .. "Call require('line-justice').setup() first.",
        vim.log.levels.ERROR
      )
    end
    return ""
  end

  -- Do not render in nofile buffers (e.g. file trees, dashboards, pickers)
  if vim.bo.buftype == "nofile" then
    return ""
  end

  if args.virtnum == 0 then
    -- ── Real line ────────────────────────────────────────────────────────

    -- Absolute line number highlight
    local abs_hl
    if args.relnum == 0 then
      abs_hl = "%#LineJusticeCursorLine#"
    elseif args.lnum > vim.fn.line(".") then
      if _state.fade_enabled then
        local tier = get_abs_tier(args.relnum, _state.fade_bands)
        abs_hl = "%#LineJusticeAbsoluteBelow" .. tier .. "#"
      else
        abs_hl = "%#LineJusticeAbsoluteBelow#"
      end
    else
      if _state.fade_enabled then
        local tier = get_abs_tier(args.relnum, _state.fade_bands)
        abs_hl = "%#LineJusticeAbsoluteAbove" .. tier .. "#"
      else
        abs_hl = "%#LineJusticeAbsoluteAbove#"
      end
    end

    -- Relative line number highlight
    local rel_hl
    if args.relnum == 0 then
      rel_hl = "%#LineJusticeCursorLine#"
    elseif args.lnum > vim.fn.line(".") then
      if _state.fade_enabled then
        local tier = get_rel_tier(args.relnum, _state.fade_bands)
        rel_hl = "%#LineJusticeRelativeBelow" .. tier .. "#"
      else
        rel_hl = "%#LineJusticeRelativeBelow#"
      end
    else
      if _state.fade_enabled then
        local tier = get_rel_tier(args.relnum, _state.fade_bands)
        rel_hl = "%#LineJusticeRelativeAbove" .. tier .. "#"
      else
        rel_hl = "%#LineJusticeRelativeAbove#"
      end
    end

    -- Format both numbers
    local abs_num = format_line_number(args.lnum)
    -- Cursor line: leave the relative column blank (never show "0")
    local rel_num = args.relnum == 0 and "" or format_line_number(args.relnum)

    -- Fixed-width columns (accounts for thousands-separator commas)
    local total_lines = vim.fn.line("$")
    local num_digits  = #tostring(total_lines)
    local num_commas  = math.floor((num_digits - 1) / 3)
    local col_w       = num_digits + num_commas

    -- Right-align the absolute number
    abs_num = string.rep(" ", math.max(0, col_w - #abs_num)) .. abs_num

    -- Right-align the relative number with separator space
    -- The separator space is included in the relative column width
    rel_num = " " .. string.rep(" ", math.max(0, col_w - #rel_num)) .. rel_num

    -- Add trailing space to ensure separation from buffer content
    return abs_hl .. abs_num .. rel_hl .. rel_num .. " "

  else
    -- ── Soft-wrapped continuation line ──────────────────────────────────
    -- Calculate the total gutter width (same formula as above so
    -- the indicator is always centred in the correct field).
    local total_lines = vim.fn.line("$")
    local num_digits  = #tostring(total_lines)
    local num_commas  = math.floor((num_digits - 1) / 3)
    local col_w       = num_digits + num_commas
    local gutter_w    = col_w + 1 + col_w

    -- Centre the indicator in the full gutter width
    local centred = centre(_state.indicator_char, gutter_w)
    return "%#LineJusticeWrappedLine#" .. centred
  end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---The statuscol.nvim segment function for line-justice.
---
--- Assigned at module load — never nil. Wire it into your statuscol config:
---
---   local lj = require("line-justice")
---   lj.setup()
---
---   require("statuscol").setup({
---     segments = {
---       { text = { lj.segment }, click = "v:lua.ScLa" },
---     },
---   })
---
--- The function closes over internal state that setup() mutates in place.
--- This means:
---   • statuscol can capture lj.segment before setup() is called
---   • re-calling setup() (e.g. to switch theme) takes effect immediately
---     without re-wiring statuscol
---   • if the segment is rendered before setup() has been called, a one-shot
---     ERROR notification is emitted and an empty string is returned
---
--- You can place other segments (gitsigns, diagnostics, etc.) freely around
--- it — line-justice never calls statuscol.setup() itself, so there is no
--- conflict with your own statuscol configuration.
---
---@type fun(args: table): string
M.segment = _segment

---Initialise line-justice.nvim.
---
--- Registers highlight groups, sets up colorscheme sync, builds the segment
--- function, and enables the number/relativenumber options that statuscol
--- requires to populate args.lnum and args.relnum.
---
--- setup() does NOT call statuscol.setup(). Wire the segment yourself — see
--- M.segment above and examples/lazy-spec.lua.
---
--- ── The simplest setup ──────────────────────────────────────────────────────
---
---   require("line-justice").setup()
---
--- ── Choosing a built-in theme ───────────────────────────────────────────────
---
---   require("line-justice").setup({ line_numbers = { theme = "Horizon" } })
---   require("line-justice").setup({ line_numbers = { theme = "Dawn" } })
---   require("line-justice").setup({ line_numbers = { theme = "Midnight" } })
---
--- ── Auto-detect colours from your colorscheme ───────────────────────────────
---
---   require("line-justice").setup({ line_numbers = { theme = nil } })
---
--- ── Named wrapped-line indicator ────────────────────────────────────────────
---
---   require("line-justice").setup({
---     wrapped_lines = { indicator = "Arrow" },   -- ↳
---   })
---
---   -- Other built-ins: "None", "Chevron", "Dot", "Ellipsis", "Bar"
---
--- ── Custom wrapped-line indicator ───────────────────────────────────────────
---
---   require("line-justice").setup({
---     wrapped_lines = { indicator = "Custom", custom = "⤷" },
---   })
---
--- ── Full example ────────────────────────────────────────────────────────────
---
---   require("line-justice").setup({
---     line_numbers = {
---       theme = "Horizon",
---       overrides = {
---         CursorLine = { fg = "#ff9e64", bold = true },
---       },
---     },
---     wrapped_lines = {
---       indicator = "Custom",
---       custom    = "╰",
---     },
---   })
---
---@param opts? LineJusticeConfig  Partial config; deep-merged with defaults
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- After deep-merging with defaults these are always present; the `or {}`
  -- guards satisfy the type checker for the optional LuaDoc annotations.
  local ln_cfg = config.line_numbers  or {}
  local wl_cfg = config.wrapped_lines or {}

  -- Resolve the named theme into a concrete colour table via the registry
  local theme_tbl = {}
  if ln_cfg.theme then
    local resolved = M.themes.get(ln_cfg.theme)
    if resolved then
      theme_tbl = resolved
    else
      -- themes.get() already emitted the WARN; continue with empty table
      theme_tbl = {}
    end
  end

  -- Resolve the wrapped-line indicator character (validated once at setup)
  local indicator_char = resolve_indicator(wl_cfg)

  -- Capture fade config for highlight resolution and render-time state.
  -- After the deep-merge this is always a table; the cast satisfies the checker.
  ---@type LineJusticeFade|nil
  local fade_cfg = ln_cfg.fade

  -- number + relativenumber must both be true for statuscol to populate
  -- args.lnum and args.relnum correctly. These are functional requirements,
  -- not stylistic preferences.
  vim.o.number         = true
  vim.o.relativenumber = true

  -- Perform initial highlight resolution (includes banded fade groups).
  resolve_highlights(ln_cfg.overrides, theme_tbl, fade_cfg)

  -- Re-resolve whenever the user switches colorscheme so colours stay in sync.
  -- Both the theme, overrides, and fade config are re-applied on top of the
  -- new scheme. fade_cfg is captured by closure — no re-read needed.
  local grp = vim.api.nvim_create_augroup("LineJusticeColorScheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group    = grp,
    callback = function() resolve_highlights(ln_cfg.overrides, theme_tbl, fade_cfg) end,
  })

  -- Update mutable render state so the already-captured segment function
  -- picks up the new config without statuscol needing to be re-wired.
  _state.indicator_char = indicator_char
  _state.fade_enabled   = fade_cfg ~= nil and fade_cfg.enabled ~= false
  _state.fade_bands     = ((fade_cfg and fade_cfg.bands)
                          or defaults.line_numbers.fade.bands) --[[@as table]]
  _state.ready          = true
end

---Return the current resolved configuration.
---@return LineJusticeConfig
function M.get_config()
  return config
end

return M

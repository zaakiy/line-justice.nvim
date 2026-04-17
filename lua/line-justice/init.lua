-- line-justice.nvim — dual absolute/relative line numbers via statuscol.nvim
--
-- Highlight resolution priority (highest → lowest):
--   1. User-provided highlights in setup() opts
--   2. Named preset (opts.statuscol.preset)
--   3. Auto-detected from the active colorscheme's built-in highlight groups
--   4. Hardcoded fallback defaults

---@class LineJusticeHighlights
---@field cursor?    table  vim.api.nvim_set_hl-compatible table for the cursor line number
---@field abs_above? table  Absolute line number, lines above the cursor
---@field abs_below? table  Absolute line number, lines below the cursor
---@field rel_above? table  Relative line number, lines above the cursor
---@field rel_below? table  Relative line number, lines below the cursor
---@field wrapped?   table  Wrapped-line continuation indicator (↳)

---@class LineJusticeStatuscol
---@field enabled?     boolean              Enable statuscol integration (default: true)
---@field relculright? boolean              Right-align cursor line number (default: true)
---@field preset?      string               Named colour preset. One of: "horizon" (default: nil — auto-detect)
---@field bt_ignore?   string[]             Buffer types (&buftype) where line-justice is disabled.
---                                         Matched exactly. Common values: "nofile", "nowrite",
---                                         "acwrite", "quickfix", "terminal", "help", "prompt", "popup".
---@field highlights?  LineJusticeHighlights Per-key colour overrides; merged on top of preset / auto-detect

---@class LineJusticeConfig
---@field statuscol? LineJusticeStatuscol

-- ---------------------------------------------------------------------------
-- Defaults
-- ---------------------------------------------------------------------------

---@type LineJusticeConfig
local defaults = {
  statuscol = {
    enabled = true,
    relculright = true,
    -- preset = nil,  -- set to "horizon" to use the built-in horizon palette
    -- Buffer types (&buftype) to ignore. Matched exactly by statuscol.nvim.
    bt_ignore = {
      "nofile",   -- scratch/unnamed buffers, most plugin UIs
    },
    highlights = {},
  },
}

---@type LineJusticeConfig
local config = {}

local M = {}

-- ---------------------------------------------------------------------------
-- Presets
-- ---------------------------------------------------------------------------

-- Built-in named colour presets.
-- Each entry is a LineJusticeHighlights-compatible table.
--
-- "horizon"
--   Inspired by a crisp horizon line: cool blue-purple sky above, fresh
--   green earth below.  These are the exact colours from the author's
--   original hand-crafted statuscol config, preserved here for anyone
--   using a TokyoNight-family colorscheme or simply wanting that look.
--
--   Colour breakdown:
--     cursor    #bb9af7  — soft violet, stands out on the cursor line
--     abs_above #565f89  — muted blue-grey  (absolute numbers, above cursor)
--     abs_below #41664f  — deep forest green (absolute numbers, below cursor)
--     rel_above #7b9ac7  — brighter steel blue (relative numbers, above cursor)
--     rel_below #6aa781  — brighter sage green (relative numbers, below cursor)
--     wrapped   #565f89  — same muted blue-grey as abs_above, italicised
--
---@type table<string, LineJusticeHighlights>
local PRESETS = {
  horizon = {
    cursor    = { fg = "#bb9af7", bold = true },
    abs_above = { fg = "#565f89" },
    abs_below = { fg = "#41664f" },
    rel_above = { fg = "#7b9ac7" },
    rel_below = { fg = "#6aa781" },
    wrapped   = { fg = "#565f89", italic = true },
  },
}

-- ---------------------------------------------------------------------------
-- Fallback defaults (used only when auto-detect yields nothing and no preset)
-- ---------------------------------------------------------------------------

-- These mirror the "horizon" palette and act as the last resort so the
-- plugin always renders something sensible even on an unknown colorscheme.
---@type LineJusticeHighlights
local FALLBACK_DEFAULTS = {
  cursor    = { fg = "#bb9af7", bold = true },
  abs_above = { fg = "#565f89" },
  abs_below = { fg = "#41664f" },
  rel_above = { fg = "#7b9ac7" },
  rel_below = { fg = "#6aa781" },
  wrapped   = { fg = "#565f89", italic = true },
}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---Format a line number with thousands separators.
---@param num number The line number to format
---@return string    Formatted string, e.g. 1234 → "1,234"
local function format_line_number(num)
  local str = tostring(num)
  return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

---Convert a numeric colour value (as returned by nvim_get_hl) to a hex string.
---@param num number  Integer colour, 0–16777215
---@return string     e.g. "#7aa2f7"
local function numeric_to_hex(num)
  return string.format("#%06x", num)
end

-- ---------------------------------------------------------------------------
-- Highlight resolution
-- ---------------------------------------------------------------------------

---Resolve and register the LineJustice* highlight groups.
---
--- Priority order (highest → lowest):
---   1. `user_hl`   — per-key overrides from setup() opts.statuscol.highlights
---   2. `preset_hl` — colours from opts.statuscol.preset (e.g. "horizon")
---   3. colorscheme — fg derived from NeoVim's own built-in highlight groups
---   4. FALLBACK_DEFAULTS — hardcoded last resort
---
---@param user_hl   LineJusticeHighlights  Per-key user overrides (may be empty)
---@param preset_hl LineJusticeHighlights  Preset colours (may be empty)
local function resolve_highlights(user_hl, preset_hl)
  user_hl   = user_hl   or {}
  preset_hl = preset_hl or {}

  ---Try to read the `fg` of a NeoVim highlight group and return it as hex.
  ---Returns nil if the group doesn't exist or has no fg.
  ---@param hl_name string
  ---@return string|nil
  local function try_get_hl_fg(hl_name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_name, link = false })
    if ok and hl and hl.fg then
      return numeric_to_hex(hl.fg)
    end
    return nil
  end

  ---Build the final highlight table for one slot.
  ---
  --- Resolution steps:
  ---   1. Start with the colorscheme-derived fg (first match wins).
  ---   2. Layer the preset value on top (preset overrides colorscheme).
  ---   3. Layer the user value on top (user overrides everything).
  ---   4. If still no `fg`, fall back to FALLBACK_DEFAULTS.
  ---
  ---@param key          string    Slot name, e.g. "cursor"
  ---@param scheme_names string[]  Ordered list of NeoVim hl groups to probe
  ---@return table                 vim.api.nvim_set_hl-compatible table
  local function resolve(key, scheme_names)
    local base = {}

    -- Step 1: colorscheme auto-detect
    for _, hl_name in ipairs(scheme_names) do
      local fg = try_get_hl_fg(hl_name)
      if fg then
        base.fg = fg
        break
      end
    end

    -- Step 2: preset (overrides colorscheme-derived fg)
    if preset_hl[key] then
      base = vim.tbl_deep_extend("force", base, preset_hl[key])
    end

    -- Step 3: user override (highest priority)
    if user_hl[key] then
      base = vim.tbl_deep_extend("force", base, user_hl[key])
    end

    -- Step 4: fallback — ensure there is always a colour
    if not base.fg then
      base = vim.tbl_deep_extend("force", base, FALLBACK_DEFAULTS[key] or {})
    end

    return base
  end

  -- Resolve each slot, listing which NeoVim groups to probe for auto-detect
  local resolved = {
    cursor    = resolve("cursor",    { "CursorLineNr" }),
    abs_above = resolve("abs_above", { "LineNr" }),
    abs_below = resolve("abs_below", { "LineNrAbove", "Comment" }),
    rel_above = resolve("rel_above", { "LineNr" }),
    rel_below = resolve("rel_below", { "LineNrBelow", "String" }),
    wrapped   = resolve("wrapped",   { "NonText" }),
  }

  -- Register highlight groups used in the statuscolumn string
  vim.api.nvim_set_hl(0, "LineJusticeCursor",    resolved.cursor)
  vim.api.nvim_set_hl(0, "LineJusticeAbsAbove",  resolved.abs_above)
  vim.api.nvim_set_hl(0, "LineJusticeAbsBelow",  resolved.abs_below)
  vim.api.nvim_set_hl(0, "LineJusticeRelAbove",  resolved.rel_above)
  vim.api.nvim_set_hl(0, "LineJusticeRelBelow",  resolved.rel_below)
  vim.api.nvim_set_hl(0, "LineJusticeWrapped",   resolved.wrapped)
end

-- ---------------------------------------------------------------------------
-- statuscol setup
-- ---------------------------------------------------------------------------

---Configure statuscol.nvim with the LineJustice dual-number segment.
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

  local cfg = config.statuscol

  -- Resolve the preset table (empty if no preset is set)
  local preset_hl = {}
  if cfg.preset then
    preset_hl = PRESETS[cfg.preset]
    if not preset_hl then
      vim.notify(
        "[line-justice] Unknown preset '" .. cfg.preset .. "'. "
          .. "Available presets: " .. table.concat(vim.tbl_keys(PRESETS), ", "),
        vim.log.levels.WARN
      )
      preset_hl = {}
    end
  end

  -- Initial highlight resolution
  resolve_highlights(cfg.highlights, preset_hl)

  -- Re-resolve whenever the colorscheme changes so colours stay in sync.
  -- (Preset and user overrides are always re-applied on top of the new scheme.)
  local group = vim.api.nvim_create_augroup("LineJusticeColorScheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      resolve_highlights(cfg.highlights, preset_hl)
    end,
  })

  -- Wire up statuscol with the dual-number segment
  statuscol.setup({
    relculright = cfg.relculright,
    bt_ignore   = cfg.bt_ignore,
    segments = {
      {
        text = {
          function(args)
            if args.virtnum == 0 then
              -- ── Highlight: absolute line number ──────────────────────────
              local abs_hl
              if args.relnum == 0 then
                abs_hl = "%#LineJusticeCursor#"
              elseif args.lnum > vim.fn.line(".") then
                abs_hl = "%#LineJusticeAbsBelow#"
              else
                abs_hl = "%#LineJusticeAbsAbove#"
              end

              -- ── Highlight: relative line number ──────────────────────────
              local rel_hl
              if args.relnum == 0 then
                rel_hl = "%#LineJusticeCursor#"
              elseif args.lnum > vim.fn.line(".") then
                rel_hl = "%#LineJusticeRelBelow#"
              else
                rel_hl = "%#LineJusticeRelAbove#"
              end

              -- ── Format numbers ───────────────────────────────────────────
              local abs_num = format_line_number(args.lnum)
              -- Cursor line: leave the relative column blank (not "0")
              local rel_num = args.relnum == 0 and "" or format_line_number(args.relnum)

              -- ── Column width (accounts for thousands-separator commas) ───
              local total_lines  = vim.fn.line("$")
              local num_digits   = #tostring(total_lines)
              local num_commas   = math.floor((num_digits - 1) / 3)
              local line_num_w   = num_digits + num_commas

              -- Right-align the absolute number
              local abs_padding = string.rep(" ", math.max(0, line_num_w - #abs_num))
              abs_num = abs_padding .. abs_num

              -- Pad the relative number so the total gutter width stays fixed
              local target_w  = line_num_w + 1 + line_num_w
              local current_w = #abs_num + 1 + #rel_num
              local rel_padding = string.rep(" ", math.max(0, target_w - current_w))

              return abs_hl .. abs_num .. " " .. rel_hl .. rel_num .. rel_padding
            else
              -- Soft-wrapped continuation lines
              return "%#LineJusticeWrapped#↳ "
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
--- Example — use defaults (auto-detect colours from colorscheme):
---
---   require("line-justice").setup()
---
--- Example — use the "horizon" preset:
---
---   require("line-justice").setup({
---     statuscol = { preset = "horizon" },
---   })
---
--- Example — manual colour overrides (merged on top of preset / auto-detect):
---
---   require("line-justice").setup({
---     statuscol = {
---       preset = "horizon",          -- start from the horizon palette …
---       highlights = {
---         cursor = { fg = "#ff9e64", bold = true },  -- … then override just cursor
---       },
---     },
---   })
---
---@param opts? LineJusticeConfig  Partial config; deep-merged with defaults
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  if config.statuscol.enabled then
    M._setup_statuscol()
  end
end

---Return the current resolved configuration.
---@return LineJusticeConfig
function M.get_config()
  return config
end

return M

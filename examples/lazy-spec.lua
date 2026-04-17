-- Drop this into your lazy.nvim plugins directory, e.g.
-- ~/.config/nvim/lua/plugins/line-justice.lua
--
-- ─────────────────────────────────────────────────────────────────────────────
-- WRAPPED-LINE INDICATOR
-- ─────────────────────────────────────────────────────────────────────────────
--
-- When a line is too long and wraps, NeoVim renders continuation lines in
-- the gutter. line-justice can show a small indicator character there,
-- centred in the gutter width, to visually distinguish wrapped continuations
-- from real lines.
--
-- wrapped_lines.indicator  (string)
--   "None"     — blank gutter, no character shown (default)
--   "Arrow"    — ↳  classic turn-down arrow
--   "Chevron"  — ›  single right-pointing chevron
--   "Dot"      — ·  middle dot / interpunct
--   "Ellipsis" — …  horizontal ellipsis
--   "Bar"      — │  thin vertical bar
--   "Custom"   — use whatever you set in wrapped_lines.custom
--
-- wrapped_lines.custom  (string)
--   Only used when indicator = "Custom".
--   Examples: "»", "⤷", "▸", "→", "╰"
--
-- ─────────────────────────────────────────────────────────────────────────────
-- COLOUR THEMES
-- ─────────────────────────────────────────────────────────────────────────────
--
-- line_numbers.theme     (string | nil)
--   "Horizon" — built-in palette: cool blues above, greens below (default)
--   nil       — auto-detect from your active colorscheme
--
-- line_numbers.overrides (table | nil)
--   Per-key tweaks on top of the theme or auto-detect.
--   Keys: CursorLine, AbsoluteAbove, AbsoluteBelow,
--         RelativeAbove, RelativeBelow, WrappedLine
--
-- ─────────────────────────────────────────────────────────────────────────────

return {
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  event = "VeryLazy",

  -- ── Option A: defaults — Horizon theme, no wrapped indicator ──────────────
  opts = {
    line_numbers  = { theme = "Horizon" },
    wrapped_lines = { indicator = "None" },
  },

  -- ── Option B: Arrow indicator (↳) ─────────────────────────────────────────
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   wrapped_lines = { indicator = "Arrow" },  -- ↳
  -- },

  -- ── Option C: Chevron indicator (›) ───────────────────────────────────────
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   wrapped_lines = { indicator = "Chevron" }, -- ›
  -- },

  -- ── Option D: Dot indicator (·) ───────────────────────────────────────────
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   wrapped_lines = { indicator = "Dot" },     -- ·
  -- },

  -- ── Option E: Ellipsis indicator (…) ──────────────────────────────────────
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   wrapped_lines = { indicator = "Ellipsis" }, -- …
  -- },

  -- ── Option F: Bar indicator (│) ───────────────────────────────────────────
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   wrapped_lines = { indicator = "Bar" },     -- │
  -- },

  -- ── Option G: Custom indicator ────────────────────────────────────────────
  -- Use any character you like. Some ideas: "»" "⤷" "▸" "→" "╰"
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   wrapped_lines = {
  --     indicator = "Custom",
  --     custom    = "⤷",
  --   },
  -- },

  -- ── Option H: auto-detect colours + custom indicator ──────────────────────
  -- opts = {
  --   line_numbers  = { theme = nil },           -- derive from colorscheme
  --   wrapped_lines = { indicator = "Arrow" },
  -- },

  -- ── Option I: full control ────────────────────────────────────────────────
  -- opts = {
  --   line_numbers = {
  --     theme = "Horizon",
  --     overrides = {
  --       CursorLine    = { fg = "#ff9e64", bold = true },
  --       AbsoluteAbove = { fg = "#565f89" },
  --       AbsoluteBelow = { fg = "#41664f" },
  --       RelativeAbove = { fg = "#7b9ac7" },
  --       RelativeBelow = { fg = "#6aa781" },
  --       WrappedLine   = { fg = "#565f89", italic = true },
  --     },
  --   },
  --   wrapped_lines = {
  --     indicator = "Custom",
  --     custom    = "╰",
  --   },
  -- },
}

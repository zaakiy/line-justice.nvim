-- Drop this into your lazy.nvim plugins directory, e.g.
-- ~/.config/nvim/lua/plugins/line-justice.lua
--
-- ─────────────────────────────────────────────────────────────────────────────
-- HOW COLOURS WORK
-- ─────────────────────────────────────────────────────────────────────────────
--
-- line_numbers.theme     (string | nil)
--   The name of a built-in colour palette.
--   "Horizon" — cool blue-purple sky above the cursor, fresh green below.
--               The author's original hand-crafted colours, designed for
--               TokyoNight-family colorschemes but great on any dark theme.
--   nil       — auto-detect colours from your active colorscheme instead.
--
-- line_numbers.overrides (table | nil)
--   Per-key colour tweaks applied ON TOP of the theme or auto-detect result.
--   Any key you omit is left exactly as the theme / auto-detect defines it.
--   Useful for swapping one or two colours without redefining everything.
--
-- Resolution priority (highest → lowest):
--   1. overrides  — your per-key tweaks
--   2. theme      — the named built-in palette
--   3. colorscheme auto-detect
--   4. hardcoded fallback (always something sensible)
--
-- Available override keys:
--   CursorLine    — the line the cursor is on
--   AbsoluteAbove — absolute numbers on lines above the cursor
--   AbsoluteBelow — absolute numbers on lines below the cursor
--   RelativeAbove — relative distance for lines above the cursor
--   RelativeBelow — relative distance for lines below the cursor
--   WrappedLine   — the ↳ indicator on soft-wrapped continuation lines
--
-- ─────────────────────────────────────────────────────────────────────────────

return {
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  event = "VeryLazy",

  -- ── Option A: Horizon theme (default) ─────────────────────────────────────
  -- The out-of-the-box experience. No configuration required — just works.
  opts = {
    line_numbers = {
      theme = "Horizon",
    },
  },

  -- ── Option B: auto-detect colours from your colorscheme ───────────────────
  -- Derives all colours from NeoVim's own highlight groups (LineNr,
  -- CursorLineNr, etc.). Updates automatically on :colorscheme.
  -- opts = {
  --   line_numbers = {
  --     theme = nil,
  --   },
  -- },

  -- ── Option C: Horizon theme with one colour overridden ────────────────────
  -- Keeps all of Horizon's colours except the cursor line, which is swapped
  -- to a warm orange. Any key left out stays as Horizon defines it.
  -- opts = {
  --   line_numbers = {
  --     theme = "Horizon",
  --     overrides = {
  --       CursorLine = { fg = "#ff9e64", bold = true },
  --     },
  --   },
  -- },

  -- ── Option D: auto-detect with selective overrides ────────────────────────
  -- Uses your colorscheme for most colours but pins a couple of specific ones.
  -- opts = {
  --   line_numbers = {
  --     theme = nil,
  --     overrides = {
  --       AbsoluteAbove = { fg = "#7aa2f7" },
  --       RelativeBelow = { fg = "#9ece6a" },
  --     },
  --   },
  -- },

  -- ── Option E: fully manual — take complete control ────────────────────────
  -- All six keys provided. Neither the theme nor auto-detect is used.
  -- opts = {
  --   line_numbers = {
  --     theme = nil,
  --     overrides = {
  --       CursorLine    = { fg = "#bb9af7", bold = true },
  --       AbsoluteAbove = { fg = "#565f89" },
  --       AbsoluteBelow = { fg = "#41664f" },
  --       RelativeAbove = { fg = "#7b9ac7" },
  --       RelativeBelow = { fg = "#6aa781" },
  --       WrappedLine   = { fg = "#565f89", italic = true },
  --     },
  --   },
  -- },
}

-- Drop this into your lazy.nvim plugins directory, e.g.
-- ~/.config/nvim/lua/plugins/line-justice.lua
--
-- Preset options
-- ──────────────
-- line-justice ships with named colour presets. Set `preset` to one of:
--
--   "horizon"  Cool blue-purple sky above the cursor, fresh green earth
--              below.  These are the author's original hand-crafted colours,
--              designed for TokyoNight-family colorschemes but usable with any
--              dark theme.
--
-- Leave `preset` unset (or nil) to auto-detect colours from your active
-- colorscheme instead.

return {
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  event = "VeryLazy",

  -- ── Option A: auto-detect colours from your colorscheme (default) ────────
  opts = {},

  -- ── Option B: use the built-in "horizon" preset ───────────────────────────
  -- opts = {
  --   statuscol = {
  --     preset = "horizon",
  --   },
  -- },

  -- ── Option C: "horizon" preset with a single colour override ─────────────
  -- opts = {
  --   statuscol = {
  --     preset = "horizon",
  --     highlights = {
  --       -- Override any individual slot; the rest come from the preset.
  --       -- cursor    = { fg = "#ff9e64", bold = true },
  --       -- abs_above = { fg = "#565f89" },
  --       -- abs_below = { fg = "#41664f" },
  --       -- rel_above = { fg = "#7b9ac7" },
  --       -- rel_below = { fg = "#6aa781" },
  --       -- wrapped   = { fg = "#565f89", italic = true },
  --     },
  --   },
  -- },

  -- ── Option D: fully manual colours (no preset, no auto-detect) ───────────
  -- opts = {
  --   statuscol = {
  --     highlights = {
  --       cursor    = { fg = "#bb9af7", bold = true },
  --       abs_above = { fg = "#565f89" },
  --       abs_below = { fg = "#41664f" },
  --       rel_above = { fg = "#7b9ac7" },
  --       rel_below = { fg = "#6aa781" },
  --       wrapped   = { fg = "#565f89", italic = true },
  --     },
  --   },
  -- },
}
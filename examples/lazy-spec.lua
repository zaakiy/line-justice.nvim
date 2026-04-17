-- Drop this into your lazy.nvim plugins directory, e.g.
-- ~/.config/nvim/lua/plugins/line-justice.lua

return {
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  event = "VeryLazy",

  -- ── Option A: auto-detect colours from your colorscheme (default) ────────
  opts = {},

  -- ── Option B: use the built-in "Horizon" preset ───────────────────────────
  -- opts = {
  --   line_numbers = {
  --     preset = "Horizon",
  --   },
  -- },

  -- ── Option C: "Horizon" preset with individual colour overrides ───────────
  -- opts = {
  --   line_numbers = {
  --     preset = "Horizon",
  --     theme = {
  --       -- Override any slot; the rest come from the preset.
  --       -- CursorLine    = { fg = "#ff9e64", bold = true },
  --       -- AbsoluteAbove = { fg = "#565f89" },
  --       -- AbsoluteBelow = { fg = "#41664f" },
  --       -- RelativeAbove = { fg = "#7b9ac7" },
  --       -- RelativeBelow = { fg = "#6aa781" },
  --       -- WrappedLine   = { fg = "#565f89", italic = true },
  --     },
  --   },
  -- },

  -- ── Option D: fully manual colours (no preset, no auto-detect) ───────────
  -- opts = {
  --   line_numbers = {
  --     theme = {
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

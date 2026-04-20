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
-- STATUSCOL PASSTHROUGH
-- ─────────────────────────────────────────────────────────────────────────────
--
-- line-justice owns exactly one statuscol segment (the dual line-number
-- renderer). The statuscol passthrough lets you add extra segments around it
-- so that other plugins — most commonly gitsigns — can coexist in the same
-- statuscolumn without you having to configure statuscol.nvim directly.
--
-- statuscol.segments_before  (table[])
--   statuscol segments inserted to the LEFT of the line-justice segment.
--   Typical use: gitsigns sign column, diagnostic signs.
--
-- statuscol.segments_after  (table[])
--   statuscol segments inserted to the RIGHT of the line-justice segment.
--
-- statuscol.options  (table)
--   Extra top-level keys merged into statuscol.setup().
--   The keys relculright, bt_ignore, and segments are always controlled by
--   line-justice and will be silently ignored if provided here.
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
    wrapped_lines = { indicator = "Bar" },
  },

  config = function(_, opts)
    -- Place any additional setup logic here, or just pass opts straight through.
    require("line-justice").setup(opts)
  end,

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

  -- ── Option J: gitsigns sign column on the left ────────────────────────────
  -- Requires gitsigns.nvim. Enable numhl in gitsigns and add its sign column
  -- as a segment_before so it sits to the left of the line-justice numbers.
  --
  -- In your gitsigns setup:
  --   require("gitsigns").setup({ numhl = true, signcolumn = true })
  --
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   wrapped_lines = { indicator = "Bar" },
  --   statuscol = {
  --     segments_before = {
  --       -- "%s" renders the sign column; ScSa is the click handler
  --       { text = { "%s" }, click = "v:lua.ScSa" },
  --     },
  --   },
  -- },

  -- ── Option K: extra statuscol top-level options ───────────────────────────
  -- Pass any statuscol.setup() key that line-justice does not manage.
  -- (relculright, bt_ignore, and segments are always owned by line-justice.)
  --
  -- opts = {
  --   line_numbers  = { theme = "Horizon" },
  --   statuscol = {
  --     options = {
  --       ft_ignore = { "NvimTree", "neo-tree" },
  --     },
  --   },
  -- },
}

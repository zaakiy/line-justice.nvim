-- Drop this into your lazy.nvim plugins directory, e.g.
-- ~/.config/nvim/lua/plugins/line-justice.lua
--
-- ─────────────────────────────────────────────────────────────────────────────
-- HOW IT WORKS
-- ─────────────────────────────────────────────────────────────────────────────
--
-- line-justice is a statuscol.nvim segment provider. It owns colour themes,
-- highlight group registration, number formatting, wrapped-line rendering,
-- AND the statuscol.setup() call. You never need to call statuscol.setup()
-- yourself — line-justice does it internally when you call lj.setup().
--
-- bt_ignore = { "nofile" } is always enforced: the custom statuscolumn is
-- never applied to non-file buffers (quickfix, terminal, prompt, etc.).
--
-- Minimal wiring — just call setup():
--
--   require("line-justice").setup()
--
-- setup() automatically enables vim.o.number and vim.o.relativenumber — both
-- are required for statuscol to populate args.lnum and args.relnum correctly.
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
--   "None"     — blank gutter, no character shown
--   "Arrow"    — ↳  classic turn-down arrow
--   "Chevron"  — ›  single right-pointing chevron
--   "Dot"      — ·  middle dot / interpunct
--   "Ellipsis" — …  horizontal ellipsis
--   "Bar"      — │  thin vertical bar (default)
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
--   "Dawn"    — warm amber and rose tones
--   "Midnight"— cool monochrome blue-greys
--   nil       — auto-detect from your active colorscheme
--
-- line_numbers.overrides (table | nil)
--   Per-key tweaks on top of the theme or auto-detect.
--   Keys: CursorLine, AbsoluteAbove, AbsoluteBelow,
--         RelativeAbove, RelativeBelow, WrappedLine
--
-- ─────────────────────────────────────────────────────────────────────────────
-- STATUSCOL INTEGRATION
-- ─────────────────────────────────────────────────────────────────────────────
--
-- statuscol.*  controls the statuscol.setup() call made by line-justice:
--
--   statuscol.bt_ignore      — buftype blocklist. "nofile" is ALWAYS included.
--                              Default: { "nofile" }
--   statuscol.ft_ignore      — filetype blocklist.
--                              Default: {}
--   statuscol.relculright    — right-align relative line numbers.
--                              Default: false
--   statuscol.left_segments  — statuscol segment tables prepended to the
--                              line-justice segment (e.g. sign column).
--   statuscol.right_segments — statuscol segment tables appended to the
--                              line-justice segment (e.g. fold column).
--
-- ─────────────────────────────────────────────────────────────────────────────

-- ── line-justice spec ─────────────────────────────────────────────────────────
--
-- lazy = false ensures setup() runs at startup so the segment is populated
-- and statuscol is wired before any buffer is displayed.

return {
  {
    "zaakiy/line-justice.nvim",
    dependencies = { "luukvbaal/statuscol.nvim" },
    lazy = false,

    -- ── Option A: defaults — Horizon theme, Bar wrapped indicator ─────────────
    opts = {
      line_numbers  = { theme = "Horizon" },
      wrapped_lines = { indicator = "Bar" },
      -- statuscol defaults: bt_ignore = { "nofile" }, ft_ignore = {}
    },

    config = function(_, opts)
      -- setup() configures line-justice AND calls statuscol.setup() internally.
      -- No manual statuscol.setup() call is needed.
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

    -- ── Option F: Custom indicator ────────────────────────────────────────────
    -- opts = {
    --   line_numbers  = { theme = "Horizon" },
    --   wrapped_lines = { indicator = "Custom", custom = "⤷" },
    -- },

    -- ── Option G: auto-detect colours ─────────────────────────────────────────
    -- opts = {
    --   line_numbers  = { theme = nil },           -- derive from colorscheme
    --   wrapped_lines = { indicator = "Arrow" },
    -- },

    -- ── Option H: gitsigns sign column to the LEFT of line-justice ────────────
    -- opts = {
    --   line_numbers  = { theme = "Horizon" },
    --   wrapped_lines = { indicator = "Bar" },
    --   statuscol = {
    --     left_segments = {
    --       { text = { "%s" }, click = "v:lua.ScSa" }, -- sign column
    --     },
    --   },
    -- },

    -- ── Option I: fold column to the RIGHT of line-justice ────────────────────
    -- opts = {
    --   line_numbers  = { theme = "Horizon" },
    --   wrapped_lines = { indicator = "Bar" },
    --   statuscol = {
    --     right_segments = {
    --       { text = { "%C" }, click = "v:lua.ScFa" }, -- fold column
    --     },
    --   },
    -- },

    -- ── Option J: exclude additional buftypes / filetypes ─────────────────────
    -- opts = {
    --   statuscol = {
    --     bt_ignore = { "nofile", "terminal" },
    --     ft_ignore = { "NvimTree", "neo-tree", "alpha" },
    --   },
    -- },

    -- ── Option K: full line-justice config ────────────────────────────────────
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
    --   wrapped_lines = { indicator = "Custom", custom = "╰" },
    --   statuscol = {
    --     bt_ignore      = { "nofile", "terminal" },
    --     ft_ignore      = { "NvimTree", "neo-tree" },
    --     relculright    = true,
    --     left_segments  = { { text = { "%s" }, click = "v:lua.ScSa" } },
    --     right_segments = { { text = { "%C" }, click = "v:lua.ScFa" } },
    --   },
    -- },
  },
}

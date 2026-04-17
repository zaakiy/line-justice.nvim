# line-justice.nvim

**Absolute justice with relative context** — a Neovim plugin that shows both absolute and relative line numbers simultaneously, making pair programming, code reviews, and remote collaboration effortless.

---

## The Problem

**You use relative line numbers in NeoVim. Your colleagues don't.**

You're pair programming and your colleague says _"Hey, there's a bug on line 42."_ You look at your screen — is that 42 above or 42 below the cursor? They're looking at a different part of the file. Confusion ensues. You both waste five minutes finding the same line.

Or worse: a code review where someone references _"the line with the bug"_ in a 500-line file. Is it near the top? The middle? Nobody knows.

## The Solution

**LineJustice** shows you both numbers at once — every line, always:

42 &nbsp; 6 &nbsp; function handleRequest(req, res) {\
43 &nbsp; 5 &nbsp;&nbsp;&nbsp; const user = await getUser(req.params.id)\
44 &nbsp; 4 &nbsp;&nbsp;&nbsp; if (!user) {\
45 &nbsp; 3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; return res.status(404).json({ error: 'Not found' })\
46 &nbsp; 2 &nbsp;&nbsp;&nbsp; }\
47 &nbsp; 1 &nbsp;&nbsp;&nbsp; ...\
**48** &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; _← cursor is here_\
49 &nbsp; 1 &nbsp;&nbsp;&nbsp; return res.json(user)\
50 &nbsp; 2 }

- The **left column** is the absolute line number — the true position in the file.
- The **right column** is the relative distance from your cursor.
- The **cursor line** (48) is shown in bold — no relative number, just your position.

Now when your colleague says _"line 42"_, you both instantly see the same thing.
When you need to jump, you use the relative number. When you reference, you use the absolute. No confusion.

## Requirements

- **NeoVim 0.10+**
- **[luukvbaal/statuscol.nvim](https://github.com/luukvbaal/statuscol.nvim)** (required — handles the statuscolumn rendering)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  event = "VeryLazy",
  opts = {}, -- uses defaults; see Configuration section to customise
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "zaakiy/line-justice.nvim",
  requires = { "luukvbaal/statuscol.nvim" },
  config = function()
    require("line-justice").setup({})
  end,
}
```

### Manual (no plugin manager)

Clone both `luukvbaal/statuscol.nvim` and `zaakiy/line-justice.nvim`, add them to your `runtimepath`, then call `require("line-justice").setup({})` in your `init.lua`.

## Configuration

Call `require("line-justice").setup(opts)` with any options you want to override. All keys are optional — omitting them uses the defaults shown below.

```lua
require("line-justice").setup({
  statuscol = {
    enabled     = true,
    relculright = true,  -- right-align cursor line number
    preset      = nil,   -- named colour preset; "horizon" uses the built-in palette
                         -- nil = auto-detect colours from your active colorscheme
    -- ft_ignore supports case-insensitive matching and glob wildcards:
    --   *  matches any sequence of characters
    --   ?  matches exactly one character
    -- Matching is always case-insensitive, so "NvimTree" == "nvimtree".
    ft_ignore = {
      "help", "dashboard",
      "neo-*",        -- neo-tree, neo-git, ...
      "*tree",        -- NvimTree, nvim-tree, ...
      "toggleterm", "terminal", "qf", "quickfix",
      "nofile", "prompt", "packer", "lspinfo",
      "Telescope*",   -- TelescopePrompt, TelescopeResults, ...
      "Avante*",      -- avante, AvanteTodos, ...
      "neominimap", "snacks_*",
    },
    -- Per-key colour overrides merged on top of preset / auto-detect.
    -- Any key left out falls through to the preset or auto-detect.
    highlights = {
      -- cursor    = { fg = "#bb9af7", bold = true },
      -- abs_above = { fg = "#565f89" },
      -- abs_below = { fg = "#41664f" },
      -- rel_above = { fg = "#7b9ac7" },
      -- rel_below = { fg = "#6aa781" },
      -- wrapped   = { fg = "#565f89", italic = true },
    },
  },
})
```

### ft_ignore — wildcards and case-insensitivity

`ft_ignore` entries are always matched **case-insensitively**, so `"NvimTree"` and `"nvimtree"` are equivalent.

Entries may contain **glob wildcards**:

| Wildcard | Meaning |
|---|---|
| `*` | Any sequence of characters (including empty) |
| `?` | Exactly one character |

Wildcard patterns are expanded at startup against all filetypes NeoVim knows about. Plain entries (no wildcards) are kept as-is and still match filetypes that register themselves lazily after startup.

```lua
ft_ignore = {
  "neo-*",      -- matches neo-tree, neo-git, neo-composer, ...
  "*tree",      -- matches NvimTree, nvim-tree, filetree, ...
  "Telescope*", -- matches TelescopePrompt, TelescopeResults, ...
  "Avante*",    -- matches avante, AvanteTodos, AvanteInput, ...
  "snacks_*",   -- matches all snacks.nvim buffers
  "help",       -- plain exact match (case-insensitive)
}
```

---

## Colour Presets

By default line-justice auto-detects colours from your active colorscheme. You can instead pin it to a named preset via `statuscol.preset`.

### `horizon`

A cool blue-purple sky above the cursor, fresh green earth below. These are the author's original hand-crafted colours, designed for TokyoNight-family colorschemes but great on any dark theme.

| Slot | Hex | Description |
|---|---|---|
| `cursor` | `#bb9af7` | Soft violet, bold — cursor line number |
| `abs_above` | `#565f89` | Muted blue-grey — absolute numbers above cursor |
| `abs_below` | `#41664f` | Deep forest green — absolute numbers below cursor |
| `rel_above` | `#7b9ac7` | Brighter steel blue — relative numbers above cursor |
| `rel_below` | `#6aa781` | Brighter sage green — relative numbers below cursor |
| `wrapped` | `#565f89` | Muted blue-grey, italic — wrapped line indicator |

```lua
-- Use the horizon preset:
require("line-justice").setup({
  statuscol = { preset = "horizon" },
})

-- Horizon preset with one colour overridden:
require("line-justice").setup({
  statuscol = {
    preset = "horizon",
    highlights = {
      cursor = { fg = "#ff9e64", bold = true }, -- swap just the cursor colour
    },
  },
})
```

### Auto-detect (default)

When `preset` is `nil`, line-justice reads your colorscheme's built-in highlight groups and derives colours automatically. It re-resolves on every `:colorscheme` change.

| Slot | Probed groups (first match wins) |
|---|---|
| `cursor` | `CursorLineNr` |
| `abs_above` | `LineNr` |
| `abs_below` | `LineNrAbove`, `Comment` |
| `rel_above` | `LineNr` |
| `rel_below` | `LineNrBelow`, `String` |
| `wrapped` | `NonText` |

## How It Works

LineJustice delegates all statuscolumn rendering to [`statuscol.nvim`](https://github.com/luukvbaal/statuscol.nvim). It registers a single custom segment that fires for every rendered line, outputting:

- The **absolute** line number (right-aligned, with thousands separators for large files)
- A blank relative column on the cursor line, or the **relative** distance on all other lines
- A `↳` indicator for soft-wrapped continuation lines

All columns are fixed-width and highlight-aware — colours change based on whether a line is above or below the cursor.

## License

[Apache 2.0](LICENSE)

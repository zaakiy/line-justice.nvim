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
  line_numbers = {
    -- Named colour preset. "Horizon" uses the built-in palette.
    -- nil = auto-detect colours from your active colorscheme (default).
    preset = nil,

    -- Per-colour overrides. Any key left out falls through to the preset
    -- or auto-detect. All keys are optional.
    theme = {
      -- CursorLine    = { fg = "#bb9af7", bold = true },
      -- AbsoluteAbove = { fg = "#565f89" },
      -- AbsoluteBelow = { fg = "#41664f" },
      -- RelativeAbove = { fg = "#7b9ac7" },
      -- RelativeBelow = { fg = "#6aa781" },
      -- WrappedLine   = { fg = "#565f89", italic = true },
    },
  },
})
```

### Theme keys

| Key | What it colours |
|---|---|
| `CursorLine` | The line the cursor is on |
| `AbsoluteAbove` | Absolute numbers on lines above the cursor |
| `AbsoluteBelow` | Absolute numbers on lines below the cursor |
| `RelativeAbove` | Relative distance for lines above the cursor |
| `RelativeBelow` | Relative distance for lines below the cursor |
| `WrappedLine` | The ↳ indicator on soft-wrapped continuation lines |

---

## Colour Presets

By default line-justice auto-detects colours from your active colorscheme. You can instead pin it to a named preset via `line_numbers.preset`.

### `Horizon`

A cool blue-purple sky above the cursor, fresh green earth below. These are the author's original hand-crafted colours, designed for TokyoNight-family colorschemes but great on any dark theme.

| Key | Hex | Description |
|---|---|---|
| `CursorLine` | `#bb9af7` | Soft violet, bold |
| `AbsoluteAbove` | `#565f89` | Muted blue-grey |
| `AbsoluteBelow` | `#41664f` | Deep forest green |
| `RelativeAbove` | `#7b9ac7` | Brighter steel blue |
| `RelativeBelow` | `#6aa781` | Brighter sage green |
| `WrappedLine` | `#565f89` | Muted blue-grey, italic |

```lua
-- Use the Horizon preset:
require("line-justice").setup({
  line_numbers = { preset = "Horizon" },
})

-- Horizon preset with one colour overridden:
require("line-justice").setup({
  line_numbers = {
    preset = "Horizon",
    theme = {
      CursorLine = { fg = "#ff9e64", bold = true }, -- swap just the cursor colour
    },
  },
})
```

### Auto-detect (default)

When `preset` is `nil`, line-justice reads your colorscheme's built-in highlight groups and derives colours automatically. It re-resolves on every `:colorscheme` change.

| Theme key | Probed groups (first match wins) |
|---|---|
| `CursorLine` | `CursorLineNr` |
| `AbsoluteAbove` | `LineNr` |
| `AbsoluteBelow` | `LineNrAbove`, `Comment` |
| `RelativeAbove` | `LineNr` |
| `RelativeBelow` | `LineNrBelow`, `String` |
| `WrappedLine` | `NonText` |

## How It Works

LineJustice delegates all statuscolumn rendering to [`statuscol.nvim`](https://github.com/luukvbaal/statuscol.nvim). It registers a single custom segment that fires for every rendered line, outputting:

- The **absolute** line number (right-aligned, with thousands separators for large files)
- A blank relative column on the cursor line, or the **relative** distance on all other lines
- A `↳` indicator for soft-wrapped continuation lines

All columns are fixed-width and highlight-aware — colours change based on whether a line is above or below the cursor.

## License

[Apache 2.0](LICENSE)

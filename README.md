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
  opts = {
    line_numbers = { theme = "Horizon" },
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "zaakiy/line-justice.nvim",
  requires = { "luukvbaal/statuscol.nvim" },
  config = function()
    require("line-justice").setup({
      line_numbers = { theme = "Horizon" },
    })
  end,
}
```

### Manual (no plugin manager)

Clone both `luukvbaal/statuscol.nvim` and `zaakiy/line-justice.nvim`, add them to your `runtimepath`, then call `require("line-justice").setup({})` in your `init.lua`.

---

## Configuration

Call `require("line-justice").setup(opts)` with any options you want to override. All keys are optional — omitting them uses the defaults shown below.

```lua
require("line-justice").setup({
  line_numbers = {

    -- theme (string | nil)
    --   Name of a built-in colour palette, or nil to auto-detect from your
    --   active colorscheme. Default: "Horizon".
    theme = "Horizon",

    -- overrides (table | nil)
    --   Per-key colour tweaks applied on top of the theme or auto-detect.
    --   Any key you omit is left exactly as the theme/auto-detect defines it.
    --   All keys are optional; provide only the ones you want to change.
    overrides = {
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

### Colour keys

| Key | What it colours |
|---|---|
| `CursorLine` | The line the cursor is currently on |
| `AbsoluteAbove` | Absolute line numbers on lines above the cursor |
| `AbsoluteBelow` | Absolute line numbers on lines below the cursor |
| `RelativeAbove` | Relative distance for lines above the cursor |
| `RelativeBelow` | Relative distance for lines below the cursor |
| `WrappedLine` | The ↳ indicator on soft-wrapped continuation lines |

### Colour resolution priority

When determining a colour, line-justice works through this chain and stops at the first result:

| Priority | Source | Set via |
|---|---|---|
| 1 (highest) | `overrides` | `line_numbers.overrides = { Key = { fg = "..." } }` |
| 2 | Named theme | `line_numbers.theme = "Horizon"` |
| 3 | Colorscheme auto-detect | `line_numbers.theme = nil` |
| 4 (lowest) | Hardcoded fallback | always active; mirrors the Horizon palette |

---

## Built-in Themes

### `"Horizon"` _(default)_

A cool blue-purple sky above the cursor, fresh green earth below. The author's original hand-crafted colours, designed for TokyoNight-family colorschemes but great on any dark theme.

| Key | Hex | Description |
|---|---|---|
| `CursorLine` | `#bb9af7` | Soft violet, bold |
| `AbsoluteAbove` | `#565f89` | Muted blue-grey |
| `AbsoluteBelow` | `#41664f` | Deep forest green |
| `RelativeAbove` | `#7b9ac7` | Brighter steel blue |
| `RelativeBelow` | `#6aa781` | Brighter sage green |
| `WrappedLine` | `#565f89` | Muted blue-grey, italic |

### Auto-detect _(theme = nil)_

When `theme` is `nil`, line-justice reads your colorscheme's built-in highlight groups and derives colours automatically. Colours update on every `:colorscheme` change.

| Key | Probed NeoVim highlight groups (first match wins) |
|---|---|
| `CursorLine` | `CursorLineNr` |
| `AbsoluteAbove` | `LineNr` |
| `AbsoluteBelow` | `LineNrAbove`, `Comment` |
| `RelativeAbove` | `LineNr` |
| `RelativeBelow` | `LineNrBelow`, `String` |
| `WrappedLine` | `NonText` |

---

## Examples

### Just use the defaults
No configuration required — Horizon is active out of the box:
```lua
require("line-justice").setup()
```

### Use the Horizon theme explicitly
```lua
require("line-justice").setup({
  line_numbers = {
    theme = "Horizon",
  },
})
```

### Auto-detect colours from your colorscheme
```lua
require("line-justice").setup({
  line_numbers = {
    theme = nil,
  },
})
```

### Override one colour on top of Horizon
Keep all of Horizon's colours but swap the cursor line to a warm orange:
```lua
require("line-justice").setup({
  line_numbers = {
    theme = "Horizon",
    overrides = {
      CursorLine = { fg = "#ff9e64", bold = true },
    },
  },
})
```

### Override several colours on top of Horizon
```lua
require("line-justice").setup({
  line_numbers = {
    theme = "Horizon",
    overrides = {
      CursorLine    = { fg = "#ff9e64", bold = true },  -- warm orange cursor
      AbsoluteBelow = { fg = "#73daca" },               -- teal below
      RelativeBelow = { fg = "#73daca" },               -- teal relative below
    },
  },
})
```

### Override colours on top of auto-detect
```lua
require("line-justice").setup({
  line_numbers = {
    theme = nil,   -- start from your colorscheme
    overrides = {
      AbsoluteAbove = { fg = "#7aa2f7" },  -- pin absolute-above to a specific blue
      RelativeBelow = { fg = "#9ece6a" },  -- pin relative-below to a specific green
    },
  },
})
```

### Fully manual — take complete control
Set `theme = nil` and provide all six keys in `overrides`. Neither the theme nor auto-detect is used for the keys you supply:
```lua
require("line-justice").setup({
  line_numbers = {
    theme = nil,
    overrides = {
      CursorLine    = { fg = "#bb9af7", bold = true },
      AbsoluteAbove = { fg = "#565f89" },
      AbsoluteBelow = { fg = "#41664f" },
      RelativeAbove = { fg = "#7b9ac7" },
      RelativeBelow = { fg = "#6aa781" },
      WrappedLine   = { fg = "#565f89", italic = true },
    },
  },
})
```

---

## How It Works

LineJustice delegates all statuscolumn rendering to [`statuscol.nvim`](https://github.com/luukvbaal/statuscol.nvim). It registers a single custom segment that fires for every rendered line, outputting:

- The **absolute** line number (right-aligned, with thousands separators for large files)
- A blank relative column on the cursor line, or the **relative** distance on all other lines
- A `↳` indicator for soft-wrapped continuation lines

All columns are fixed-width and highlight-aware — colours change based on whether a line is above or below the cursor.

## License

[Apache 2.0](LICENSE)

# line-justice.nvim

**Absolute justice with relative context** — a Neovim plugin that shows both absolute and relative line numbers simultaneously, making pair programming, code reviews, and remote collaboration effortless.

---

## The Problem

**You use relative line numbers in NeoVim. Your colleagues don't.**

You're pair programming and your colleague says _"Hey, there's a bug on line 42."_ You look at your screen — is that 42 above or 42 below the cursor? They're looking at a different part of the file. You move the cursor. Line numbers change. Confusion ensues. You both waste five minutes finding the same line.

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
    line_numbers  = { theme = "Horizon" },
    wrapped_lines = { indicator = "None" },
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
      line_numbers  = { theme = "Horizon" },
      wrapped_lines = { indicator = "None" },
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

  wrapped_lines = {

    -- indicator (string)
    --   Named indicator preset shown in the gutter of soft-wrapped
    --   continuation lines, centred in the gutter width.
    --   Default: "None" (blank — no character shown).
    --
    --   "None"     — blank gutter
    --   "Arrow"    — ↳
    --   "Chevron"  — ›
    --   "Dot"      — ·
    --   "Ellipsis" — …
    --   "Bar"      — │
    --   "Custom"   — use the string in wrapped_lines.custom
    indicator = "None",

    -- custom (string)
    --   Only used when indicator = "Custom".
    --   Set this to any character or short string you want to display.
    --   Examples: "»", "⤷", "▸", "→", "╰"
    -- custom = "⤷",

  },

})
```

---

## Wrapped-line Indicator

When a line is too long for the window and wraps, NeoVim renders the continuation as a virtual line. `wrapped_lines.indicator` controls what appears in the gutter of those virtual lines, **centred** in the gutter width.

### Built-in indicators

| Name | Character | Description |
|---|---|---|
| `"None"` | _(blank)_ | No character — gutter is fully empty **(default)** |
| `"Arrow"` | ↳ | Classic turn-down arrow — "continued from above" |
| `"Chevron"` | › | Single right-pointing chevron — lightweight directional hint |
| `"Dot"` | · | Middle dot / interpunct — subtle and minimal |
| `"Ellipsis"` | … | Horizontal ellipsis — "more content continues" |
| `"Bar"` | │ | Thin vertical bar — structural / tree-style |
| `"Custom"` | _your string_ | Whatever you put in `wrapped_lines.custom` |

### Custom indicator

Set `indicator = "Custom"` and put your character in `custom`:

```lua
wrapped_lines = {
  indicator = "Custom",
  custom    = "⤷",   -- or: "»", "▸", "→", "╰", or any string you like
},
```

### Colour of the indicator

The indicator inherits the `WrappedLine` colour from your `line_numbers` theme or overrides:

```lua
line_numbers = {
  theme = "Horizon",
  overrides = {
    WrappedLine = { fg = "#ff9e64", italic = true }, -- change indicator colour
  },
},
```

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

### Colour resolution priority

| Priority | Source | Set via |
|---|---|---|
| 1 (highest) | `overrides` | `line_numbers.overrides = { Key = { fg = "..." } }` |
| 2 | Named theme | `line_numbers.theme = "Horizon"` |
| 3 | Colorscheme auto-detect | `line_numbers.theme = nil` |
| 4 (lowest) | Hardcoded fallback | always active; mirrors the Horizon palette |

---

## Examples

### Just use the defaults
Horizon theme, no wrapped indicator — no configuration required:
```lua
require("line-justice").setup()
```

### Arrow indicator on wrapped lines
```lua
require("line-justice").setup({
  wrapped_lines = { indicator = "Arrow" },  -- ↳
})
```

### Chevron indicator
```lua
require("line-justice").setup({
  wrapped_lines = { indicator = "Chevron" },  -- ›
})
```

### Custom indicator
```lua
require("line-justice").setup({
  wrapped_lines = {
    indicator = "Custom",
    custom    = "⤷",
  },
})
```

### Custom indicator with a custom colour
```lua
require("line-justice").setup({
  line_numbers = {
    theme = "Horizon",
    overrides = {
      WrappedLine = { fg = "#ff9e64", italic = true },
    },
  },
  wrapped_lines = {
    indicator = "Custom",
    custom    = "╰",
  },
})
```

### Auto-detect colours + Arrow indicator
```lua
require("line-justice").setup({
  line_numbers  = { theme = nil },
  wrapped_lines = { indicator = "Arrow" },
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
      CursorLine    = { fg = "#ff9e64", bold = true },
      AbsoluteBelow = { fg = "#73daca" },
      RelativeBelow = { fg = "#73daca" },
    },
  },
})
```

### Fully manual — take complete control
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
  wrapped_lines = {
    indicator = "Custom",
    custom    = "╰",
  },
})
```

---

## How It Works

LineJustice delegates all statuscolumn rendering to [`statuscol.nvim`](https://github.com/luukvbaal/statuscol.nvim). It registers a single custom segment that fires for every rendered line, outputting:

- The **absolute** line number (right-aligned, with thousands separators for large files)
- A blank relative column on the cursor line, or the **relative** distance on all other lines
- On soft-wrapped continuation lines: the configured indicator character, centred in the gutter width

All columns are fixed-width and highlight-aware — colours change based on whether a line is above or below the cursor.

## License

[Apache 2.0](LICENSE)

# line-justice.nvim

**Absolute justice with relative context** — a Neovim plugin that shows both absolute and relative line numbers simultaneously, making pair programming, code reviews, and remote collaboration effortless.

---

## The Problem

**You use relative line numbers in NeoVim. Your colleagues don't.**

You're pair programming and your colleague says _"Hey, there's a bug on line 42."_ You look at your screen — is that 42 above or 42 below the cursor? They're looking at a different part of the file. You move the cursor. Line numbers change. Confusion ensues. You both waste five minutes finding the same line.

Is it near the top? The middle? Nobody knows.

<img width="400" height="279" alt="image" src="https://github.com/user-attachments/assets/d715531c-780d-4357-b997-55d8c0c889fa" />


## The Solution

**LineJustice shows you both numbers at once — every line, always.**

42 &nbsp; 6 &nbsp; function handleRequest(req, res) {\
43 &nbsp; 5 &nbsp;&nbsp;&nbsp; const user = await getUser(req.params.id)\
44 &nbsp; 4 &nbsp;&nbsp;&nbsp; if (!user) {\
45 &nbsp; 3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; return res.status(404).json({ error: 'Not found' })\
46 &nbsp; 2 &nbsp;&nbsp;&nbsp; }\
47 &nbsp; 1 &nbsp;&nbsp;&nbsp; ...\
**48** &nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; _**← cursor is here**_\
49 &nbsp; 1 &nbsp;&nbsp;&nbsp; return res.json(user)\
50 &nbsp; 2 &nbsp; }

- The **left column** is the absolute line number — the true position in the file.
- The **right column** is the relative distance from your cursor.
- The **cursor line** (48) is shown in bold — no relative number, just your position.

Now when your colleague says _"line 42"_, you both instantly see the same thing.
When you need to jump, you use the relative number. When you reference, you use the absolute. No confusion.

## Demo
<img width="746" height="480" alt="line-justice" src="https://github.com/user-attachments/assets/7c675c89-883a-4bbe-851b-5836bfb6ea99" />



## Requirements

- **NeoVim 0.10+**
- **[luukvbaal/statuscol.nvim](https://github.com/luukvbaal/statuscol.nvim)** (required — handles the statuscolumn rendering)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- return    -- add if you don't already have it
{
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  event = "VeryLazy",
  opts = {
    line_numbers  = { theme = "Horizon" },
    wrapped_lines = { indicator = "None" },
  },
  config = function(_, opts)
    require("line-justice").setup(opts)
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

NOTE: Packer is untested. Looking for packer users to contribute any corrections.

```lua
use {
  "zaakiy/line-justice.nvim",
  requires = { "luukvbaal/statuscol.nvim" },
  opts = {
    line_numbers  = { theme = "Horizon" },
    wrapped_lines = { indicator = "None" },
  },
  config = function()
    require("line-justice").setup(opts)
  end,
}
```

### Manual (no plugin manager)

Clone both `luukvbaal/statuscol.nvim` and `zaakiy/line-justice.nvim`, add them to your `runtimepath`, then call `require("line-justice").setup({})` in your `init.lua`.

---

## Configuration

Call `require("line-justice").setup(opts)` with any options you want to override. All keys are optional — omitting them uses the defaults shown below.

```lua
opts = {

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

},    -- the comma may not be needed, depending on your situation
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

Three colour themes ship out of the box:

| Name | Vibe | Best with |
|---|---|---|
| `"Horizon"` | Cool blue-purple above, green below | TokyoNight, Catppuccin Mocha, any dark theme |
| `"Dawn"` | Warm amber and rose tones | Rosé Pine, Catppuccin Latte, Gruvbox |
| `"Midnight"` | Cool monochrome blue-greys | GitHub Dark, Zephyr, Moonfly |

```lua
require("line-justice").setup({
  line_numbers = { theme = "Horizon" },   -- default
  -- line_numbers = { theme = "Dawn" },
  -- line_numbers = { theme = "Midnight" },
})
```

Set `theme = nil` to auto-detect colours from your active colorscheme instead.

---

## Custom Themes

You can register your own colour themes at runtime using the theme registry:

```lua
local lj = require("line-justice")

-- 1. Define and register your theme
lj.themes.register({
  name        = "Forest",
  description = "Deep greens and mossy tones.",
  author      = "Your Name",          -- optional
  colors = {
    CursorLine    = { fg = "#a8ff78", bold   = true },
    AbsoluteAbove = { fg = "#4a7c59" },
    AbsoluteBelow = { fg = "#2e5b3a" },
    RelativeAbove = { fg = "#6dbf8a" },
    RelativeBelow = { fg = "#4c9e6a" },
    WrappedLine   = { fg = "#4a7c59", italic = true },
  },
})

-- 2. Use it in setup
lj.setup({
  line_numbers = { theme = "Forest" },
})
```

### Color slots

| Slot | Applied to |
|---|---|
| `CursorLine` | Absolute **and** relative columns on the cursor row |
| `AbsoluteAbove` | Absolute line numbers above the cursor |
| `AbsoluteBelow` | Absolute line numbers below the cursor |
| `RelativeAbove` | Relative distances above the cursor |
| `RelativeBelow` | Relative distances below the cursor |
| `WrappedLine` | The indicator character on soft-wrapped continuation lines |

All six slots are recommended. Any slot you omit falls through to colorscheme auto-detect or the built-in fallback (Horizon palette).

### Theme registry API

```lua
local themes = require("line-justice").themes

themes.register(spec)   -- register (or overwrite) a theme; returns true/false
themes.get("Forest")    -- returns the colors table, or nil if not found
themes.list()           -- sorted list of all available theme names
themes.exists("Forest") -- true if the name is registered or built-in
```

### Shipping a theme as a standalone file or plugin

```lua
-- my-lj-theme.lua (loaded after line-justice.nvim)
local ok, lj = pcall(require, "line-justice")
if not ok then return end

lj.themes.register({
  name   = "MyTheme",
  description = "My personal palette.",
  colors = { ... },
})
```

With lazy.nvim, add `dependencies = { "zaakiy/line-justice.nvim" }` to ensure load order.

See [`examples/custom-theme.lua`](examples/custom-theme.lua) for three fully-annotated example themes.

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

## Large Files & Thousands Separators

No code file _needs_ to be so long that its line numbers require a comma. There, it's been said.

And yet — here we are. Maybe it's generated code. Maybe it's a migration file. Maybe it's that one 4,200-line God class that everyone is too afraid to touch. LineJustice doesn't judge. It just makes sure you can still read the gutter.

Absolute line numbers are automatically formatted with **thousands-separator commas** for any file long enough to need them:

```
  997  3  end
  998  2
  999  1  -- the calm before the storm
1,000     ← cursor
1,001  1  -- line one thousand and one
1,002  2
```

The gutter width **expands automatically** as your file grows — no configuration needed, no truncation, no overlap. A 999-line file uses a 3-character gutter. A 1,000-line file promotes to 5 characters (`1,000`). A 10,000-line file uses 6 (`10,000`). It just works.

And if you're pair programming on a file with comma-separated line numbers — well, at least you'll both be able to clearly agree on exactly which line of that monolith you're staring at together.

---

## How It Works

LineJustice delegates all statuscolumn rendering to [`statuscol.nvim`](https://github.com/luukvbaal/statuscol.nvim). It registers a single custom segment that fires for every rendered line, outputting:

- The **absolute** line number (right-aligned, with **thousands-separator commas** on large files)
- A blank relative column on the cursor line, or the **relative** distance on all other lines
- On soft-wrapped continuation lines: the configured indicator character, centred in the gutter width

All columns are fixed-width and highlight-aware — colours change based on whether a line is above or below the cursor.

### Column-width formula

The gutter width is computed fresh on every render from the total line count:

```
num_digits = #tostring(total_lines)          -- e.g. 4 for a 1000-line file
num_commas = floor((num_digits - 1) / 3)     -- e.g. 1 comma in "1,000"
col_w      = num_digits + num_commas         -- e.g. 5 chars for "1,000"
gutter_w   = col_w + 1 + col_w              -- abs + space + rel
```

Both the absolute and relative columns always share the same width, so the gutter is perfectly symmetric regardless of how large the file grows.

## License

[Apache 2.0](LICENSE)

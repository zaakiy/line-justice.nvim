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
- **[luukvbaal/statuscol.nvim](https://github.com/luukvbaal/statuscol.nvim)** (required — handles statuscolumn rendering)

## How It Works

line-justice is a **statuscol.nvim segment provider**. It owns:

- Colour themes and highlight group registration
- Dual abs/rel number formatting and rendering
- Soft-wrapped continuation-line indicators

It does **not** call `statuscol.setup()`. You wire `require("line-justice").segment` into your own statuscol config. This means line-justice never conflicts with your statuscol configuration — you remain in full control of what else appears in the statuscolumn.

`setup()` automatically sets `vim.o.number = true` and `vim.o.relativenumber = true`. Both are required for statuscol to populate `args.lnum` and `args.relnum` correctly.

---

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  lazy = false,
  config = function()
    local lj = require("line-justice")
    lj.setup()

    require("statuscol").setup({
      segments = {
        { text = { lj.segment }, click = "v:lua.ScLa" },
      },
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

> **Note:** Packer is untested. Looking for packer users to contribute any corrections.

```lua
use {
  "zaakiy/line-justice.nvim",
  requires = { "luukvbaal/statuscol.nvim" },
  config = function()
    local lj = require("line-justice")
    lj.setup()

    require("statuscol").setup({
      segments = {
        { text = { lj.segment }, click = "v:lua.ScLa" },
      },
    })
  end,
}
```

### Manual (no plugin manager)

Clone both `luukvbaal/statuscol.nvim` and `zaakiy/line-justice.nvim`, add them to your `runtimepath`, then in your `init.lua`:

```lua
local lj = require("line-justice")
lj.setup()

require("statuscol").setup({
  segments = {
    { text = { lj.segment }, click = "v:lua.ScLa" },
  },
})
```

---

## Configuration

Call `require("line-justice").setup(opts)` with any options you want to override. All keys are optional — omitting them uses the defaults shown below.

```lua
local lj = require("line-justice")

lj.setup({

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
      -- CursorLine    = { fg = "#FF966C", bold = true },
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
    --   continuation lines, centred in the gutter width. Default: "Bar".
    --
    --   "None"     — blank gutter
    --   "Arrow"    — ↳
    --   "Chevron"  — ›
    --   "Dot"      — ·
    --   "Ellipsis" — …
    --   "Bar"      — │
    --   "Custom"   — use the string in wrapped_lines.custom
    indicator = "Bar",

    -- custom (string)
    --   Only used when indicator = "Custom".
    --   Set this to any character or short string you want to display.
    --   Examples: "»", "⤷", "▸", "→", "╰"
    -- custom = "⤷",

  },

})

-- Wire the segment into statuscol after setup()
require("statuscol").setup({
  segments = {
    { text = { lj.segment }, click = "v:lua.ScLa" },
  },
})
```

---

## Other Plugins in the Statuscolumn

Because line-justice never calls `statuscol.setup()`, you have complete freedom over what else appears in the statuscolumn. Place other segments around `lj.segment` in your statuscol config.

### gitsigns sign column

```lua
-- In your gitsigns setup:
require("gitsigns").setup({
  numhl      = true,
  signcolumn = true,
})

-- In your statuscol setup — sign column to the LEFT of line-justice:
require("statuscol").setup({
  segments = {
    { text = { "%s" },        click = "v:lua.ScSa" }, -- sign column
    { text = { lj.segment },  click = "v:lua.ScLa" }, -- line-justice
  },
})
```

### Fold column

```lua
require("statuscol").setup({
  segments = {
    { text = { lj.segment }, click = "v:lua.ScLa" }, -- line-justice
    { text = { "%C" },        click = "v:lua.ScFa" }, -- fold column
  },
})
```

### statuscol top-level options

Any `statuscol.setup()` key (`relculright`, `bt_ignore`, `ft_ignore`, etc.) can be passed freely alongside the segments:

```lua
require("statuscol").setup({
  relculright = true,
  bt_ignore   = { "nofile" },
  ft_ignore   = { "NvimTree", "neo-tree" },
  segments    = {
    { text = { lj.segment }, click = "v:lua.ScLa" },
  },
})
```

---

## Wrapped-line Indicator

When a line is too long for the window and wraps, NeoVim renders the continuation as a virtual line. `wrapped_lines.indicator` controls what appears in the gutter of those virtual lines, **centred** in the gutter width.

### Built-in indicators

| Name | Character | Description |
|---|---|---|
| `"None"` | _(blank)_ | No character — gutter is fully empty |
| `"Arrow"` | ↳ | Classic turn-down arrow — "continued from above" |
| `"Chevron"` | › | Single right-pointing chevron — lightweight directional hint |
| `"Dot"` | · | Middle dot / interpunct — subtle and minimal |
| `"Ellipsis"` | … | Horizontal ellipsis — "more content continues" |
| `"Bar"` | │ | Thin vertical bar — structural / tree-style **(default)** |
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
lj.setup({ line_numbers = { theme = "Horizon" } })   -- default
-- lj.setup({ line_numbers = { theme = "Dawn" } })
-- lj.setup({ line_numbers = { theme = "Midnight" } })
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

-- 3. Wire the segment
require("statuscol").setup({
  segments = {
    { text = { lj.segment }, click = "v:lua.ScLa" },
  },
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
  name        = "MyTheme",
  description = "My personal palette.",
  colors = { ... },
})
```

With lazy.nvim, add `dependencies = { "zaakiy/line-justice.nvim" }` to ensure load order.

See [`examples/custom-theme.lua`](examples/custom-theme.lua) for three fully-annotated example themes.

---

## Examples

### Minimal — just the defaults

```lua
local lj = require("line-justice")
lj.setup()

require("statuscol").setup({
  segments = { { text = { lj.segment }, click = "v:lua.ScLa" } },
})
```

### Arrow indicator on wrapped lines

```lua
lj.setup({ wrapped_lines = { indicator = "Arrow" } })  -- ↳
```

### Custom indicator

```lua
lj.setup({
  wrapped_lines = { indicator = "Custom", custom = "⤷" },
})
```

### Custom indicator with a custom colour

```lua
lj.setup({
  line_numbers = {
    theme = "Horizon",
    overrides = {
      WrappedLine = { fg = "#ff9e64", italic = true },
    },
  },
  wrapped_lines = { indicator = "Custom", custom = "╰" },
})
```

### Auto-detect colours from colorscheme

```lua
lj.setup({
  line_numbers  = { theme = nil },
  wrapped_lines = { indicator = "Arrow" },
})
```

### Override one colour on top of Horizon

Keep all of Horizon's colours but swap the cursor line to a warm orange:

```lua
lj.setup({
  line_numbers = {
    theme = "Horizon",
    overrides = {
      CursorLine = { fg = "#ff9e64", bold = true },
    },
  },
})
```

### Fully manual — take complete control

```lua
lj.setup({
  line_numbers = {
    theme = nil,
    overrides = {
      CursorLine    = { fg = "#FF966C", bold = true },
      AbsoluteAbove = { fg = "#565f89" },
      AbsoluteBelow = { fg = "#41664f" },
      RelativeAbove = { fg = "#7b9ac7" },
      RelativeBelow = { fg = "#6aa781" },
      WrappedLine   = { fg = "#565f89", italic = true },
    },
  },
  wrapped_lines = { indicator = "Custom", custom = "╰" },
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

## Architecture

### Column-width formula

The gutter width is computed fresh on every render from the total line count:

```
num_digits = #tostring(total_lines)          -- e.g. 4 for a 1000-line file
num_commas = floor((num_digits - 1) / 3)     -- e.g. 1 comma in "1,000"
col_w      = num_digits + num_commas         -- e.g. 5 chars for "1,000"
gutter_w   = col_w + 1 + col_w              -- abs + space + rel
```

Both the absolute and relative columns always share the same width, so the gutter is perfectly symmetric regardless of how large the file grows.

### Responsibility boundary

| Owned by line-justice | Owned by you (via statuscol) |
|---|---|
| Highlight group registration | `statuscol.setup()` call |
| Colour theme resolution | Segment placement and ordering |
| Number formatting and rendering | Other segments (signs, folds, etc.) |
| Wrapped-line indicator | `relculright`, `bt_ignore`, `ft_ignore`, … |
| `vim.o.number` / `vim.o.relativenumber` | Everything else |

## License

[Apache 2.0](LICENSE)

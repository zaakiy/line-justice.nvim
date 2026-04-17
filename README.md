# line-justice.nvim

**Absolute justice with relative context** — a Neovim plugin that shows both absolute and relative line numbers simultaneously, making pair programming, code reviews, and remote collaboration effortless.

---

## The Problem

**You use relative line numbers in NeoVim. Your colleagues don't.**

You're pair programming and your colleague says _"Hey, there's a bug on line 42."_ You look at your screen — is that 42 above or 42 below the cursor? They're looking at a different part of the file. Confusion ensues. You both waste five minutes finding the same line.

Or worse: a code review where someone references _"the line with the bug"_ in a 500-line file. Is it near the top? The middle? Nobody knows.

## The Solution

**LineJustice** shows you both numbers at once — every line, always:

```
  42  16  function handleRequest(req, res) {
  43  15    const user = await getUser(req.params.id)
  44  14    if (!user) {
  45  13      return res.status(404).json({ error: 'Not found' })
  46  12    }
  47  11    ...
  48      ←  cursor is here
  49   1    return res.json(user)
  50   2  }
```

- The **left column** is the absolute line number — the true position in the file.
- The **right column** is the relative distance from your cursor.

Now when your colleague says _"line 42"_, you both instantly see the same thing.
When you need to jump, you use the relative number. When you reference, you use the absolute. No confusion.

## Requirements

- **NeoVim 0.10+** (for `statuscolumn` support)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "zaakiy/line-justice.nvim",
  event = "VeryLazy",
  opts = {}, -- uses defaults; see Configuration section to customise
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "zaakiy/line-justice.nvim",
  config = function()
    require("line-justice").setup({})
  end,
}
```

### Manual (no plugin manager)

Clone the repository and add it to your `runtimepath`, then call `require("line-justice").setup({})` in your `init.lua`.

## Configuration

Call `require("line-justice").setup(opts)` with any options you want to override. All keys are optional — omitting them uses the defaults shown below.

```lua
require("line-justice").setup({
  -- Core dual line number display
  line_numbers = {
    enabled   = true,
    abs_width = 0,       -- 0 = auto (based on total line count, min 3)
    rel_width = 3,       -- reserved width for the relative column
    separator = " ",     -- string between absolute and relative columns
    abs_hl    = "LineNr",        -- highlight group for absolute numbers
    rel_hl    = "LineNrAbove",   -- highlight group for relative numbers
    cur_hl    = "CursorLineNr",  -- highlight group for the cursor line
  },

  -- nvim-treesitter-context integration (optional dependency)
  treesitter_context = {
    enabled    = true,
    multiwindow = true,
    line_numbers = false,  -- must be false to avoid alignment conflicts
    separator  = "-",
  },

  -- mason-lspconfig integration (optional dependency)
  lsp = {
    enabled           = true,
    ensure_installed  = { "ts_ls" },
    automatic_enable  = true,
    keymaps = {
      -- action = "key"  (action names listed in the LSP section below)
      hover = "K",
      -- definition  = "gd",
      -- references  = "gr",
      -- rename      = "<leader>rn",
      -- code_action = "<leader>ca",
      -- format      = "<leader>f",
    },
  },
})
```

### Available LSP keymap actions

| Action | Description |
|---|---|
| `hover` | Show hover documentation |
| `definition` | Go to definition |
| `references` | List references |
| `declaration` | Go to declaration |
| `type_definition` | Go to type definition |
| `implementation` | Go to implementation |
| `rename` | Rename symbol |
| `code_action` | Open code actions |
| `format` | Format buffer |
| `signature_help` | Show signature help |

## Commands

| Command | Description |
|---|---|
| `:LineJusticeToggle` | Toggle dual line numbers on/off |
| `:LineJusticeEnable` | Enable LineJustice |
| `:LineJusticeDisable` | Disable LineJustice, restore NeoVim defaults |

## nvim-treesitter-context Compatibility

If you use [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context), LineJustice can auto-configure it for you — just set `treesitter_context.enabled = true` (the default).

If you prefer to configure it yourself, set `treesitter_context.enabled = false` and use these settings to avoid alignment issues:

```lua
{
  "nvim-treesitter/nvim-treesitter-context",
  opts = {
    multiwindow  = true,
    line_numbers = false, -- REQUIRED: prevents misalignment with statuscol
    separator    = "-",
  },
}
```

> **Why?** treesitter-context renders its own line numbers that don't align with LineJustice's custom `statuscolumn`. Disabling them lets LineJustice handle all numbering consistently. The separator gives a clear visual boundary between the context pane and content.

## How It Works

LineJustice sets NeoVim's `statuscolumn` option to a Lua expression that is evaluated for every rendered line. It uses `v:lnum` (absolute) and `v:relnum` (relative) to build a fixed-width, highlight-aware column string — no timers, no autocmds on cursor movement, no performance cost beyond what NeoVim already does to render the gutter.

## License

[Apache 2.0](LICENSE)

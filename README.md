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
  42   6  function handleRequest(req, res) {
  43   5    const user = await getUser(req.params.id)
  44   4    if (!user) {
  45   3      return res.status(404).json({ error: 'Not found' })
  46   2    }
  47   1    ...
  48      ←  cursor is here
  49   1    return res.json(user)
  50   2  }
```

- The **left column** is the absolute line number — the true position in the file.
- The **right column** is the relative distance from your cursor.

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
  -- statuscol.nvim integration (required dependency)
  statuscol = {
    enabled     = true,
    relculright = true, -- right-align cursor line number
    -- File types where LineJustice is disabled
    ft_ignore = {
      "help", "dashboard", "neo-tree", "NvimTree",
      "toggleterm", "terminal", "qf", "quickfix",
      "nofile", "prompt", "packer", "lspinfo",
      "TelescopePrompt", "avante", "AvanteTodos", "neominimap",
    },
    -- Highlight group colours (any vim.api.nvim_set_hl-compatible table)
    highlights = {
      abs        = { fg = "#7aa2f7" },           -- absolute numbers
      abs_above  = { fg = "#565f89" },           -- absolute, above cursor
      abs_below  = { fg = "#41664f" },           -- absolute, below cursor
      cursor     = { fg = "#bb9af7", bold = true }, -- cursor line
      rel_above  = { fg = "#7b9ac7" },           -- relative, above cursor
      rel_below  = { fg = "#6aa781" },           -- relative, below cursor
      wrapped    = { fg = "#565f89", italic = true }, -- wrapped line indicator
    },
  },

  -- nvim-treesitter-context integration (optional)
  treesitter_context = {
    enabled      = true,
    multiwindow  = true,
    line_numbers = false, -- must be false to avoid alignment conflicts
    separator    = "-",
  },

  -- mason-lspconfig integration (optional)
  lsp = {
    enabled          = true,
    ensure_installed = { "ts_ls" },
    automatic_enable = true,
    keymaps = {
      -- action = "key", e.g.:
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

## nvim-treesitter-context Compatibility

LineJustice can auto-configure `nvim-treesitter-context` for you when `treesitter_context.enabled = true` (the default). If you prefer to manage it yourself, set `treesitter_context.enabled = false` and apply these settings manually to avoid alignment issues:

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

> **Why?** treesitter-context renders its own line numbers that conflict with statuscol.nvim's custom gutter. Disabling them lets LineJustice control all numbering consistently. The separator gives a clear visual boundary between the context pane and content.

## How It Works

LineJustice delegates all statuscolumn rendering to [`statuscol.nvim`](https://github.com/luukvbaal/statuscol.nvim). It registers a single custom segment that fires for every rendered line, outputting:

- The **absolute** line number (right-aligned, with thousands separators for large files)
- A blank relative column on the cursor line, or the **relative** distance on all other lines
- A `↳` indicator for soft-wrapped continuation lines

All columns are fixed-width and highlight-aware — colours change based on whether a line is above or below the cursor.

## License

[Apache 2.0](LICENSE)

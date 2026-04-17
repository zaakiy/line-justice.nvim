# AGENTS.md — line-justice.nvim Handover Document

> This document is intended for developers taking over or contributing to the project.
> It captures architecture, design decisions, conventions, and practical guidance needed
> to get up to speed quickly.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Layout](#2-repository-layout)
3. [Architecture & Data Flow](#3-architecture--data-flow)
4. [Configuration System](#4-configuration-system)
5. [Colour / Highlight System](#5-colour--highlight-system)
6. [Wrapped-Line Indicators](#6-wrapped-line-indicators)
7. [Public API](#7-public-api)
8. [Internal Helpers Reference](#8-internal-helpers-reference)
9. [statuscol.nvim Integration](#9-statuscolnvim-integration)
10. [Development Guidelines](#10-development-guidelines)
11. [Adding a New Feature — Step-by-step](#11-adding-a-new-feature--step-by-step)
12. [Theme Config Management](#12-theme-config-management)
13. [Adding a New Wrapped-Line Indicator Preset](#13-adding-a-new-wrapped-line-indicator-preset)
14. [Testing Checklist](#14-testing-checklist)
15. [Common Issues & Fixes](#15-common-issues--fixes)
16. [Git Conventions](#16-git-conventions)
17. [Dependencies](#17-dependencies)
18. [License](#18-license)

---

## 1. Project Overview

**line-justice.nvim** is a Neovim plugin that renders **both absolute and relative line numbers simultaneously** in the statuscolumn, solving a real-world friction point for pair programming, code reviews, and remote collaboration.

- The **left column** always shows the true (absolute) line number in the file.
- The **right column** shows the cursor-relative distance on every non-cursor line.
- The **cursor line** itself is highlighted distinctly (no relative number shown — it would always be `0`).
- Soft-wrapped continuation lines show a configurable indicator character instead of any numbers.

All rendering is delegated to [`luukvbaal/statuscol.nvim`](https://github.com/luukvbaal/statuscol.nvim).

**Minimum NeoVim version:** 0.10  
**Language:** Lua  
**License:** Apache 2.0  
**Remote:** `https://github.com/zaakiy/line-justice.nvim`

---

## 2. Repository Layout

```
line-justice.nvim/
├── lua/
│   └── line-justice/
│       ├── init.lua                ← Plugin entry point, config, statuscol wiring
│       └── themes/
│           ├── init.lua            ← Theme registry (register, get, list, exists)
│           ├── horizon.lua         ← Built-in Horizon theme spec
│           ├── dawn.lua            ← Built-in Dawn theme spec
│           └── midnight.lua        ← Built-in Midnight theme spec
├── plugin/
│   └── line-justice.lua      ← Auto-sourced entry point; double-load guard + version check
├── examples/
│   ├── lazy-spec.lua         ← Full lazy.nvim plugin spec with Options A–I
│   └── custom-theme.lua      ← Annotated example showing how to author and register a custom theme
├── README.md                 ← End-user documentation
├── SYSTEM_PROMPT.md          ← AI-assistant development context (gitignored)
├── LICENSE                   ← Apache 2.0
└── .gitignore
```

### Key facts

| File | Role |
|---|---|
| `lua/line-justice/init.lua` | Plugin entry point. Contains types, defaults, helpers, highlight resolution, statuscol wiring, and public API. Theme data moved to `themes/`. |
| `lua/line-justice/themes/init.lua` | Theme registry. Exposes `register()`, `get()`, `list()`, `exists()`. Loads built-in specs lazily. |
| `lua/line-justice/themes/horizon.lua` | Horizon theme spec (`LineJusticeThemeSpec`). |
| `lua/line-justice/themes/dawn.lua` | Dawn theme spec — warm amber and rose tones. |
| `lua/line-justice/themes/midnight.lua` | Midnight theme spec — cool monochrome blue-greys. |
| `examples/custom-theme.lua` | Annotated example showing how to author and register a custom theme. |
| `plugin/line-justice.lua` | NeoVim auto-sources everything under `plugin/`. This file sets `vim.g.loaded_line_justice` to prevent double-loading and checks `nvim-0.10`. |
| `examples/lazy-spec.lua` | Not loaded by NeoVim. Purely illustrative for users installing via lazy.nvim. |
| `SYSTEM_PROMPT.md` | Listed in `.gitignore`. Not shipped. Used for AI-assisted development sessions. |

---

## 3. Architecture & Data Flow

```
User calls require("line-justice").setup(opts)
        │
        ▼
M.setup(opts)
  └─ vim.tbl_deep_extend("force", defaults, opts)  → config
  └─ M._setup_statuscol()
        │
        ├─ require("statuscol")            [errors with vim.notify WARN if absent]
        │
        ├─ Resolve theme table
        │    M.themes.get(config.line_numbers.theme)  or {}
        │    (loads from themes/init.lua registry; built-ins lazy-loaded)
        │
        ├─ resolve_indicator(config.wrapped_lines)
        │    → indicator_char  (string, may be "")
        │
        ├─ resolve_highlights(overrides, theme_tbl)
        │    → sets NeoVim hl groups: LineJustice{CursorLine,AbsoluteAbove,
        │      AbsoluteBelow,RelativeAbove,RelativeBelow,WrappedLine}
        │
        ├─ vim.api.nvim_create_autocmd("ColorScheme", ...)
        │    → re-runs resolve_highlights on every :colorscheme change
        │
        └─ statuscol.setup({ segments = { { text = { fn } } } })
               └─ fn(args) called by statuscol for every statuscolumn render
                    args.virtnum == 0  → real line  → abs + rel numbers
                    args.virtnum != 0  → wrap line  → centred indicator_char
```

### Highlight group names registered

| NeoVim group | Used for |
|---|---|
| `LineJusticeCursorLine` | Absolute & relative columns on the cursor row |
| `LineJusticeAbsoluteAbove` | Absolute numbers for lines above cursor |
| `LineJusticeAbsoluteBelow` | Absolute numbers for lines below cursor |
| `LineJusticeRelativeAbove` | Relative numbers for lines above cursor |
| `LineJusticeRelativeBelow` | Relative numbers for lines below cursor |
| `LineJusticeWrappedLine` | Wrapped-line indicator character |

---

## 4. Configuration System

### Schema (LuaDoc types in `init.lua`)

```
LineJusticeConfig
├── line_numbers  (LineJusticeLineNumbers)
│   ├── theme      string | nil   "Horizon" | nil (auto-detect)
│   └── overrides  LineJusticeOverrides
│       ├── CursorLine?     { fg, bold? }
│       ├── AbsoluteAbove?  { fg }
│       ├── AbsoluteBelow?  { fg }
│       ├── RelativeAbove?  { fg }
│       ├── RelativeBelow?  { fg }
│       └── WrappedLine?    { fg, italic? }
└── wrapped_lines (LineJusticeWrappedLines)
    ├── indicator  string   "None"|"Arrow"|"Chevron"|"Dot"|"Ellipsis"|"Bar"|"Custom"
    └── custom     string   character used when indicator="Custom"
```

### Defaults

```lua
{
  line_numbers = {
    theme     = "Horizon",
    overrides = {},
  },
  wrapped_lines = {
    indicator = "None",
    custom    = "",
  },
}
```

### Internal constants (not user-facing)

```lua
INTERNAL = {
  bt_ignore   = { "nofile" },  -- skip plugin-managed buffers (file trees, dashboards, etc.)
  relculright = true,          -- right-align cursor-line number in relative column
}
```

These are passed directly to `statuscol.setup()` and are **intentionally hidden** from users. Do not expose them in the public API without good reason.

### Config merging

`vim.tbl_deep_extend("force", defaults, opts or {})` — user opts always win, and only provided keys are overridden; the rest fall through to defaults.

---

## 5. Colour / Highlight System

### Resolution priority (highest → lowest)

| Priority | Source | How to activate |
|---|---|---|
| 1 | `line_numbers.overrides` | `overrides = { CursorLine = { fg = "#..." } }` |
| 2 | Named theme (`THEMES` table) | `theme = "Horizon"` |
| 3 | Colorscheme auto-detect | `theme = nil` (probes NeoVim highlight groups) |
| 4 | `FALLBACK` table | always active — mirrors Horizon palette |

### Auto-detect probes

When `theme = nil`, each colour slot probes a list of NeoVim highlight groups in order, using the first one that has a non-nil `fg`:

| Slot | Probed groups |
|---|---|
| `CursorLine` | `CursorLineNr` |
| `AbsoluteAbove` | `LineNr` |
| `AbsoluteBelow` | `LineNrAbove`, `Comment` |
| `RelativeAbove` | `LineNr` |
| `RelativeBelow` | `LineNrBelow`, `String` |
| `WrappedLine` | `NonText` |

### Built-in themes

Three themes ship out of the box. All are defined as `LineJusticeThemeSpec` files under `lua/line-justice/themes/` and loaded lazily by the registry.

#### Horizon (default)

| Slot | Hex | Description |
|---|---|---|
| `CursorLine` | `#FF966C` | Soft violet, bold |
| `AbsoluteAbove` | `#565f89` | Muted blue-grey |
| `AbsoluteBelow` | `#41664f` | Deep forest green |
| `RelativeAbove` | `#7b9ac7` | Brighter steel blue |
| `RelativeBelow` | `#6aa781` | Brighter sage green |
| `WrappedLine` | `#565f89` | Muted blue-grey, italic |

#### Dawn

| Slot | Hex | Description |
|---|---|---|
| `CursorLine` | `#d4885a` | Warm amber-orange, bold |
| `AbsoluteAbove` | `#9a7560` | Muted earth brown |
| `AbsoluteBelow` | `#7d5c3b` | Deeper wood brown |
| `RelativeAbove` | `#c9a87c` | Sandy gold |
| `RelativeBelow` | `#b07d5e` | Terracotta |
| `WrappedLine` | `#9a7560` | Earth brown, italic |

#### Midnight

| Slot | Hex | Description |
|---|---|---|
| `CursorLine` | `#a9b1d6` | Pale blue-white, bold |
| `AbsoluteAbove` | `#4e5579` | Cool dark slate |
| `AbsoluteBelow` | `#3b4068` | Deeper navy slate |
| `RelativeAbove` | `#6c7494` | Medium slate blue |
| `RelativeBelow` | `#565e7a` | Softer slate |
| `WrappedLine` | `#4e5579` | Dark slate, italic |

### ColorScheme autocmd

`resolve_highlights()` is wired to the `ColorScheme` autocommand in the `LineJusticeColorScheme` augroup. Every `:colorscheme` change automatically re-registers all six highlight groups. The augroup is created with `{ clear = true }` so repeated `setup()` calls do not accumulate duplicate listeners.

---

## 6. Wrapped-Line Indicators

### Built-in presets (`WRAPPED_INDICATORS` table)

| Name | Character | Description |
|---|---|---|
| `"None"` | _(empty string)_ | Default — blank gutter |
| `"Arrow"` | `↳` | Classic turn-down arrow |
| `"Chevron"` | `›` | Single right chevron |
| `"Dot"` | `·` | Middle dot |
| `"Ellipsis"` | `…` | Horizontal ellipsis |
| `"Bar"` | `│` | Thin vertical bar |
| `"Custom"` | _(user-defined)_ | `wrapped_lines.custom` value |

### Validation (`resolve_indicator`)

- `"Custom"` with empty `custom` → `vim.notify` WARN, returns `""`.
- Unknown preset name → `vim.notify` WARN (lists valid names), returns `""`.
- Resolved once at `setup()` time; the result (`indicator_char`) is captured in the statuscol segment closure.

### Centering (`centre` helper)

The indicator character is centred in the total gutter width using the same width formula as the number columns, so visual alignment is always consistent regardless of file size.

---

## 7. Public API

### `require("line-justice").setup(opts?)`

Initialises the plugin. Safe to call multiple times (re-creates highlights and re-wires statuscol). `opts` is deep-merged with defaults — all keys are optional.

```lua
require("line-justice").setup({
  line_numbers  = { theme = "Horizon" },
  wrapped_lines = { indicator = "None" },
})
```

### `require("line-justice").get_config()`

Returns the current resolved `LineJusticeConfig` table. Useful for debugging or reading settings in another plugin.

### `require("line-justice").themes` _(sub-module)_

The theme registry, exposed as a public sub-module. See [Section 12](#12-theme-config-management) for the full API reference.

```lua
local themes = require("line-justice").themes
themes.register(spec)    -- register a custom theme
themes.list()            -- list all available theme names
themes.exists("Dawn")   -- check if a theme is available
themes.get("Midnight")  -- get a theme's colors table
```

### `M._setup_statuscol()` _(private)_

Prefixed with `_` to signal it is internal. Called by `setup()`. Users should never call this directly — it always requires `config` to be populated first.

---

## 8. Internal Helpers Reference

All helpers are `local` to `init.lua` and not exported.

| Function | Signature | Purpose |
|---|---|---|
| `format_line_number(num)` | `number → string` | Formats integers with thousands-separator commas (e.g. `1234` → `"1,234"`). Gutter width is computed from the formatted length, so columns expand automatically as the file grows. |
| `numeric_to_hex(num)` | `number → string` | Converts a NeoVim colour integer to a `#rrggbb` hex string. |
| `resolve_indicator(wl_cfg)` | `LineJusticeWrappedLines → string` | Validates and returns the indicator character; emits WARN for unknown/empty. |
| `centre(str, width)` | `(string, number) → string` | Centres `str` in a field of `width` chars with space padding. |
| `resolve_highlights(overrides, theme_tbl)` | `(table, table) → nil` | Resolves all six colour slots and calls `vim.api.nvim_set_hl` for each. |

---

## 9. statuscol.nvim Integration

line-justice delegates **all** statuscolumn rendering to `luukvbaal/statuscol.nvim`. It registers a single custom segment with a closure over `indicator_char`.

### Segment logic (inside `M._setup_statuscol`)

```
args.virtnum == 0  (real line)
  → abs_hl  based on: relnum==0 (cursor) / lnum > cursor (below) / else (above)
  → rel_hl  based on: relnum==0 (cursor) / lnum > cursor (below) / else (above)
  → abs_num = format_line_number(args.lnum),  right-aligned in col_w
  → rel_num = "" on cursor line, else format_line_number(args.relnum)
  → gutter width = col_w + 1 (space) + col_w
  → return "%#HL#" .. abs_num .. " " .. "%#HL#" .. rel_num .. padding

args.virtnum != 0  (soft-wrapped continuation)
  → return "%#LineJusticeWrappedLine#" .. centre(indicator_char, gutter_w)
```

### Column-width formula

```lua
local num_digits = #tostring(vim.fn.line("$"))
local num_commas = math.floor((num_digits - 1) / 3)
local col_w      = num_digits + num_commas   -- accounts for thousands separators
local gutter_w   = col_w + 1 + col_w
```

This means columns automatically grow as the file grows — no manual width configuration needed. A 999-line file uses a 3-char column; a 1,000-line file promotes to 5 chars (`1,000`); a 10,000-line file uses 6 chars (`10,000`). Both the real-line path and the wrapped-line path use the **exact same formula** — keep them in sync or the wrapped indicator will be off-centre.

> **Note:** No code file _needs_ to be so long that its line numbers require a comma. But if it is, at least both people staring at the gutter during a pair-programming session will be looking at the same, clearly formatted number.

### `bt_ignore`

Set to `{ "nofile" }`. This prevents statuscol from applying the custom segment to plugin-managed buffers (file explorers, dashboards, pickers, floating windows, etc.). This is considered sufficient coverage; the original `ft_ignore` approach was deliberately removed in favour of the simpler `bt_ignore`.

---

## 10. Development Guidelines

### Lua style

- Follow standard NeoVim plugin conventions.
- Use LuaDoc annotations (`---@param`, `---@return`, `---@class`, `---@type`, `---@field`) — the existing code is fully annotated; please maintain this.
- Use `pcall()` for all `require()` calls on optional dependencies.
- Use `vim.notify()` (with appropriate `vim.log.levels.*`) for all user-visible warnings and errors — never `print()` or `error()`.
- Use `vim.tbl_deep_extend("force", ...)` for merging tables.

### Error handling pattern

```lua
local ok, mod = pcall(require, "some-optional-dep")
if not ok then
  vim.notify("[line-justice] 'some-optional-dep' not found. Install it to use X.", vim.log.levels.WARN)
  return
end
```

### New feature pattern

```lua
-- 1. Add to defaults
local defaults = {
  my_feature = {
    enabled = true,
    some_opt = "default_value",
  },
}

-- 2. Create internal setup function
---@private
function M._setup_my_feature()
  if not config.my_feature.enabled then return end
  -- implementation
end

-- 3. Call from M.setup()
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})
  M._setup_statuscol()
  M._setup_my_feature()
end
```

### Do not expose INTERNAL constants

The `INTERNAL` table (`bt_ignore`, `relculright`) is intentionally hidden from users. These values tune statuscol.nvim's behaviour and should remain internal implementation details.

---

## 11. Adding a New Feature — Step-by-step

1. **Add default config** to the `defaults` table in `init.lua`.
2. **Add LuaDoc types** — create or extend a `@class` if the feature introduces new config keys.
3. **Implement** in a private `M._setup_<feature>()` function.
4. **Call it** conditionally from `M.setup()`.
5. **Update README.md** — new config section, examples.
6. **Update `examples/lazy-spec.lua`** if the feature changes the recommended lazy.nvim spec.
7. **Test** with and without optional dependencies; test with defaults only.

---

## 12. Theme Config Management

### Architecture

Themes are managed by a dedicated registry module at `lua/line-justice/themes/init.lua`.
Built-in themes live as individual spec files (`horizon.lua`, `dawn.lua`, `midnight.lua`) and are **loaded lazily** — only when first requested. The registry is exposed publicly as `require("line-justice").themes`.

### Registry API

| Function | Signature | Returns | Description |
|---|---|---|---|
| `register(spec)` | `LineJusticeThemeSpec → boolean` | `true` on success | Validate and store a theme. Emits WARN and returns `false` if validation fails. |
| `get(name)` | `string → LineJusticeOverrides\|nil` | colors table or nil | Load and return a theme's colors. Lazy-loads built-ins. Emits WARN if not found. |
| `list()` | `() → string[]` | sorted name list | All registered + all built-in names (sorted alphabetically). |
| `exists(name)` | `string → boolean` | bool | True if the name is registered or is a built-in. |

### LineJusticeThemeSpec shape

```lua
---@type LineJusticeThemeSpec
{
  name        = "MyTheme",          -- unique identifier (case-sensitive)
  description = "Short sentence.",  -- shown in error messages
  author      = "Your Name",        -- optional
  colors = {
    CursorLine    = { fg = "#rrggbb", bold   = true },
    AbsoluteAbove = { fg = "#rrggbb" },
    AbsoluteBelow = { fg = "#rrggbb" },
    RelativeAbove = { fg = "#rrggbb" },
    RelativeBelow = { fg = "#rrggbb" },
    WrappedLine   = { fg = "#rrggbb", italic = true },
  },
}
```

All six color keys are recommended. Missing keys fall through to auto-detect / FALLBACK (Horizon palette).

### Adding a built-in theme (shipped with the plugin)

1. Create `lua/line-justice/themes/<name>.lua` returning a `LineJusticeThemeSpec`.
2. Add an entry to `BUILTIN_PATHS` in `lua/line-justice/themes/init.lua`:
   ```lua
   BUILTIN_PATHS["MyTheme"] = "line-justice.themes.myname"
   ```
3. Update `lua/line-justice/init.lua` LuaDoc for `LineJusticeLineNumbers.theme`.
4. Document the new theme in README.md under "Built-in Themes".
5. Add a commented example in `examples/lazy-spec.lua`.

### Registering a custom theme at runtime

Developers can register themes before or after `setup()`. Register before for the cleanest flow:

```lua
local lj = require("line-justice")

lj.themes.register({
  name        = "Forest",
  description = "Deep greens and mossy tones.",
  author      = "Jane Dev",
  colors = {
    CursorLine    = { fg = "#a8ff78", bold   = true },
    AbsoluteAbove = { fg = "#4a7c59" },
    AbsoluteBelow = { fg = "#2e5b3a" },
    RelativeAbove = { fg = "#6dbf8a" },
    RelativeBelow = { fg = "#4c9e6a" },
    WrappedLine   = { fg = "#4a7c59", italic = true },
  },
})

lj.setup({ line_numbers = { theme = "Forest" } })
```

See `examples/custom-theme.lua` for three fully-annotated example themes (Forest, Ember, Grayscale) and guidance on shipping themes as standalone files or plugins.

### Validation rules

The registry validates every spec before storing it:
- `name` — non-empty string
- `description` — non-empty string
- `colors` — table; each present color slot must be a table
- `colors.<slot>.fg` — if present, must be a `#rrggbb` hex string

A failed validation emits `vim.notify(..., WARN)` and returns `false`. The registry is never left in a corrupt state.

### Listing available themes

```vim
:lua print(vim.inspect(require("line-justice").themes.list()))
```

Returns all built-in + registered names alphabetically:
```
{ "Dawn", "Ember", "Forest", "Grayscale", "Horizon", "Midnight" }
```

---

## 13. Adding a New Wrapped-Line Indicator Preset

1. Add an entry to `WRAPPED_INDICATORS` in `init.lua`:
   ```lua
   WRAPPED_INDICATORS["MyIndicator"] = "⟶"
   ```
2. Document it in the table comment block above `WRAPPED_INDICATORS`.
3. Update the `LineJusticeWrappedLines` LuaDoc `@field indicator` list.
4. Update README.md's indicator table.
5. Add a commented-out example option in `examples/lazy-spec.lua`.

---

## 14. Testing Checklist

There is currently no automated test suite. All testing is manual. Before any non-trivial change:

- [ ] **Default config** — `require("line-justice").setup()` with no arguments works correctly.
- [ ] **Horizon theme** — numbers appear with correct colours above/below cursor.
- [ ] **Auto-detect** (`theme = nil`) — colours match the active colorscheme; switch colorschemes and verify they update live.
- [ ] **Overrides** — per-key overrides correctly override theme and auto-detect.
- [ ] **Wrapped lines** — all six built-in indicators render correctly; `Custom` with a character; `Custom` with empty string warns.
- [ ] **All three built-in themes** — `"Horizon"`, `"Dawn"`, `"Midnight"` render with correct colours.
- [ ] **Custom theme registration** — `themes.register(spec)` stores the theme; `setup({ line_numbers = { theme = "..." } })` applies it.
- [ ] **Invalid theme spec** — bad `fg` value, missing `name`, etc. emits WARN and returns `false`; plugin continues unaffected.
- [ ] **`themes.list()`** — returns sorted list including all built-ins and registered themes.
- [ ] **`themes.exists()`** — returns `true` for built-ins (even before first load) and registered themes; `false` for unknowns.
- [ ] **Unknown theme name** — emits WARN, does not crash.
- [ ] **Unknown indicator name** — emits WARN, falls back to blank.
- [ ] **Large files** (1,000+ lines) — thousands separators appear in both the absolute and relative columns; gutter widens automatically at the 1k/10k/100k boundaries; column widths are identical in both the real-line and wrapped-line code paths; no performance degradation at 10,000+ lines.
- [ ] **Missing statuscol.nvim** — emits WARN, does not crash NeoVim.
- [ ] **Plugin buffers** (file tree, dashboard, picker) — no custom statuscolumn applied.
- [ ] **Multiple `setup()` calls** — no duplicate autocmds, no crash.
- [ ] **Cross-platform** — Linux, macOS, Windows (WSL).

---

## 15. Common Issues & Fixes

| Symptom | Likely Cause | Fix |
|---|---|---|
| No dual line numbers visible | `statuscol.nvim` not installed | Install `luukvbaal/statuscol.nvim` |
| Line numbers appear in plugin windows (file tree, etc.) | `bt_ignore` not working | Verify buffer has `buftype=nofile`; check `INTERNAL.bt_ignore` |
| Colours wrong after colorscheme change | `ColorScheme` autocmd not firing | Check augroup `LineJusticeColorScheme` exists; ensure `setup()` was called |
| Thousands separator misaligned | `col_w` formula bug | Both real-line and wrap-line paths use the same formula — keep them in sync |
| Wrapped indicator not centred | `centre()` helper receiving wrong width | Verify `gutter_w = col_w + 1 + col_w` in both branches |
| `Unknown theme` warning | Typo in `theme` string | Check `themes.list()` for valid names (case-sensitive); ensure custom themes are registered before `setup()` |
| `Unknown indicator` warning | Typo in `indicator` string | Check `WRAPPED_INDICATORS` keys (case-sensitive) |
| Duplicate `ColorScheme` autocmds | `setup()` called multiple times | Already handled — augroup created with `{ clear = true }` |

---

## 16. Git Conventions

- **Branch:** work from `main`; create feature branches for non-trivial changes.
- **Commit format:** Conventional Commits style observed in the log:
  - `feat: <short description>`
  - `fix: <short description>`
  - `refactor: <short description>`
  - `docs: <short description>`
- **Commit body:** list significant sub-changes as bullet points (see `COMMIT_EDITMSG` for reference style).
- **Author:** Zak Siddiqui `<zak@kelsiem.com>`

---

## 17. Dependencies

### Required

| Dependency | Repo | Notes |
|---|---|---|
| `statuscol.nvim` | `luukvbaal/statuscol.nvim` | Handles all statuscolumn rendering. Without it, the plugin emits a WARN and does nothing. |

### Optional / future

The `SYSTEM_PROMPT.md` mentions `nvim-treesitter-context` and `mason-lspconfig` as potential future integrations, but **they are not used in the current codebase**. Any integration must be gated behind `pcall` and an `enabled` config flag.

### NeoVim version

Requires **NeoVim 0.10+**. The check lives in `plugin/line-justice.lua` and aborts with an ERROR-level notify if the version is not met.

---

## 18. License

**Apache 2.0** — see `LICENSE` in the repository root.

---

*Generated as part of senior developer handover. For questions about intent or design decisions, refer to the inline comments in `lua/line-justice/init.lua` and the commit history — both are thorough.*

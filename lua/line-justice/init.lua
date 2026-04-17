---@class LineJusticeConfig
---@field statuscol? table Configuration for statuscol.nvim integration
---@field statuscol.enabled? boolean Enable statuscol integration (default: true)
---@field statuscol.relculright? boolean Right-align cursor line number (default: true)
---@field statuscol.ft_ignore? string[] File types to skip (default: help, dashboard, etc.)
---@field statuscol.highlights? table Custom highlight overrides for auto-detected colors

---@type LineJusticeConfig
local defaults = {
  statuscol = {
    enabled = true,
    relculright = true,
    ft_ignore = {
      "help",
      "dashboard",
      "neo-tree",
      "NvimTree",
      "toggleterm",
      "terminal",
      "qf",
      "quickfix",
      "nofile",
      "prompt",
      "packer",
      "lspinfo",
      "TelescopePrompt",
      "avante",
      "AvanteTodos",
      "neominimap",
    },
    highlights = {},
  },
}

---@type LineJusticeConfig
local config = {}

local M = {}

-- Hardcoded TokyoNight defaults (lowest priority in resolution chain)
local TOKYONIGHT_DEFAULTS = {
  cursor = { fg = "#bb9af7", bold = true },
  abs_above = { fg = "#565f89" },
  abs_below = { fg = "#41664f" },
  rel_above = { fg = "#7b9ac7" },
  rel_below = { fg = "#6aa781" },
  wrapped = { fg = "#565f89", italic = true },
}

---Format a line number with thousands separators.
---@param num number The line number to format
---@return string Formatted line number (e.g., "1,234")
local function format_line_number(num)
  local str = tostring(num)
  return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

---Convert a numeric color value to hex string.
---@param num number Numeric color value (0-16777215)
---@return string Hex color string (e.g., "#7aa2f7")
local function numeric_to_hex(num)
  return string.format("#%06x", num)
end

---Resolve highlight colors from multiple sources: colorscheme, user overrides, defaults.
---Sets up LineJustice* highlight groups and registers ColorScheme autocommand for theme changes.
---@param user_hl table User-provided highlight overrides
local function resolve_highlights(user_hl)
  user_hl = user_hl or {}

  -- Attempt to read a highlight group and extract its fg color
  local function try_get_hl_fg(hl_name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_name, link = false })
    if ok and hl and hl.fg then
      return numeric_to_hex(hl.fg)
    end
    return nil
  end

  -- Resolve each highlight group with: colorscheme → user override → hardcoded default
  local function resolve(key, fallback_hl_names, defaults_key)
    local base = {}

    -- Try to get color from colorscheme via fallback_hl_names
    if fallback_hl_names then
      for _, hl_name in ipairs(fallback_hl_names) do
        local fg = try_get_hl_fg(hl_name)
        if fg then
          base.fg = fg
          break
        end
      end
    end

    -- Merge in user override (overrides colorscheme-derived color)
    if user_hl[key] then
      base = vim.tbl_deep_extend("force", base, user_hl[key])
    end

    -- Fall back to hardcoded TokyoNight default if no fg found
    if not base.fg then
      base = vim.tbl_deep_extend("force", base, TOKYONIGHT_DEFAULTS[defaults_key] or {})
    end

    return base
  end

  -- Resolve each highlight group
  local cursor = resolve("cursor", { "CursorLineNr" }, "cursor")
  local abs_above = resolve("abs_above", { "LineNr" }, "abs_above")
  local abs_below = resolve("abs_below", { "LineNrAbove", "Comment" }, "abs_below")
  local rel_above = resolve("rel_above", { "LineNr" }, "rel_above")
  local rel_below = resolve("rel_below", { "LineNrBelow", "String" }, "rel_below")
  local wrapped = resolve("wrapped", { "NonText" }, "wrapped")

  -- Register all highlight groups
  vim.api.nvim_set_hl(0, "LineJusticeCursor", cursor)
  vim.api.nvim_set_hl(0, "LineJusticeAbsAbove", abs_above)
  vim.api.nvim_set_hl(0, "LineJusticeAbsBelow", abs_below)
  vim.api.nvim_set_hl(0, "LineJusticeRelAbove", rel_above)
  vim.api.nvim_set_hl(0, "LineJusticeRelBelow", rel_below)
  vim.api.nvim_set_hl(0, "LineJusticeWrapped", wrapped)
end

---Setup statuscol.nvim with the LineJustice dual-number segment.
---@private
function M._setup_statuscol()
  local ok, statuscol = pcall(require, "statuscol")
  if not ok then
    vim.notify(
      "[line-justice] statuscol.nvim not found. "
        .. "Install luukvbaal/statuscol.nvim to use this feature.",
      vim.log.levels.WARN
    )
    return
  end

  local cfg = config.statuscol

  -- Resolve and set up highlights
  resolve_highlights(cfg.highlights)

  -- Set up ColorScheme autocommand to re-resolve highlights when theme changes
  local group = vim.api.nvim_create_augroup("LineJusticeColorScheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      resolve_highlights(cfg.highlights)
    end,
  })

  -- Configure statuscol with the dual-number segment
  statuscol.setup({
    relculright = cfg.relculright,
    ft_ignore = cfg.ft_ignore,
    segments = {
      {
        text = {
          function(args)
            if args.virtnum == 0 then
              -- Determine highlight group for absolute line number
              local abs_hl
              if args.relnum == 0 then
                abs_hl = "%#LineJusticeCursor#"
              elseif args.lnum > vim.fn.line(".") then
                abs_hl = "%#LineJusticeAbsBelow#"
              else
                abs_hl = "%#LineJusticeAbsAbove#"
              end

              -- Determine highlight group for relative line number
              local rel_hl
              if args.relnum == 0 then
                rel_hl = "%#LineJusticeCursor#"
              elseif args.lnum > vim.fn.line(".") then
                rel_hl = "%#LineJusticeRelBelow#"
              else
                rel_hl = "%#LineJusticeRelAbove#"
              end

              -- Format numbers with thousands separators
              local abs_num = format_line_number(args.lnum)
              -- Cursor line: show no relative number (blank)
              local rel_num = args.relnum == 0 and "" or format_line_number(args.relnum)

              -- Calculate column width based on total file lines
              local total_lines = vim.fn.line("$")
              local num_digits = #tostring(total_lines)
              local num_commas = math.floor((num_digits - 1) / 3)
              local line_num_width = num_digits + num_commas

              -- Right-align the absolute number
              local abs_padding = string.rep(" ", math.max(0, line_num_width - #abs_num))
              abs_num = abs_padding .. abs_num

              -- Calculate padding for relative number to maintain fixed total width
              local target_width = line_num_width + 1 + line_num_width
              local current_width = #abs_num + 1 + #rel_num
              local rel_padding = string.rep(" ", math.max(0, target_width - current_width))

              return abs_hl .. abs_num .. " " .. rel_hl .. rel_num .. rel_padding
            else
              -- Wrapped-line indicator
              return "%#LineJusticeWrapped#↳ "
            end
          end,
        },
        click = "v:lua.ScLa",
      },
    },
  })
end

---Initialize the plugin with optional configuration.
---@param opts? LineJusticeConfig User configuration options
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  if config.statuscol.enabled then
    M._setup_statuscol()
  end
end

---Get the current resolved configuration.
---@return LineJusticeConfig
function M.get_config()
  return config
end

return M

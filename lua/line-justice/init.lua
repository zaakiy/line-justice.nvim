local M = {}

-- Default configuration
local defaults = {
  -- statuscol.nvim configuration
  statuscol = {
    enabled = true,
    -- Right-align the cursor line number when using relative numbers
    relculright = true,
    -- File types where LineJustice should not apply
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
    -- Highlight groups for each part of the line number column.
    -- Override these to customise colours without touching your colorscheme.
    highlights = {
      -- Absolute line numbers
      abs        = { fg = "#7aa2f7" },
      abs_above  = { fg = "#565f89" },
      abs_below  = { fg = "#41664f" },
      cursor     = { fg = "#bb9af7", bold = true },
      -- Relative line numbers
      rel_above  = { fg = "#7b9ac7" },
      rel_below  = { fg = "#6aa781" },
      -- Wrapped-line indicator
      wrapped    = { fg = "#565f89", italic = true },
    },
  },
  -- Treesitter context configuration
  treesitter_context = {
    enabled = true,
    multiwindow = true,
    line_numbers = false,
    separator = "-",
  },
  -- LSP configuration
  lsp = {
    enabled = true,
    ensure_installed = {
      "ts_ls",
    },
    automatic_enable = true,
    keymaps = {
      hover = "K",
      -- Uncomment to enable these keymaps:
      -- definition = "gd",
      -- references = "gr",
    },
  },
}

-- User configuration (resolved after setup)
local config = {}

-- ---------------------------------------------------------------------------
-- statuscol.nvim
-- ---------------------------------------------------------------------------

--- Format a line number with thousands separators, e.g. 1234 -> "1,234".
---@param num number
---@return string
local function format_line_number(num)
  local str = tostring(num)
  return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

--- Setup statuscol.nvim with the LineJustice dual-number segment.
function M._setup_statuscol()
  local ok, statuscol = pcall(require, "statuscol")
  if not ok then
    vim.notify(
      "[line-justice] statuscol.nvim not found. " ..
      "Install luukvbaal/statuscol.nvim to use this feature.",
      vim.log.levels.WARN
    )
    return
  end

  local cfg = config.statuscol
  local hl  = cfg.highlights

  -- Define highlight groups from config
  vim.api.nvim_set_hl(0, "LineJusticeAbs",      hl.abs)
  vim.api.nvim_set_hl(0, "LineJusticeAbsAbove", hl.abs_above)
  vim.api.nvim_set_hl(0, "LineJusticeAbsBelow", hl.abs_below)
  vim.api.nvim_set_hl(0, "LineJusticeCursor",   hl.cursor)
  vim.api.nvim_set_hl(0, "LineJusticeRelAbove", hl.rel_above)
  vim.api.nvim_set_hl(0, "LineJusticeRelBelow", hl.rel_below)
  vim.api.nvim_set_hl(0, "LineJusticeWrapped",  hl.wrapped)

  statuscol.setup({
    relculright = cfg.relculright,
    ft_ignore   = cfg.ft_ignore,
    segments = {
      {
        text = {
          function(args)
            if args.virtnum == 0 then
              -- Highlight for the absolute line number
              local abs_hl
              if args.relnum == 0 then
                abs_hl = "%#LineJusticeCursor#"
              elseif args.lnum > vim.fn.line(".") then
                abs_hl = "%#LineJusticeAbsBelow#"
              else
                abs_hl = "%#LineJusticeAbsAbove#"
              end

              -- Highlight for the relative line number
              local rel_hl
              if args.relnum == 0 then
                rel_hl = "%#LineJusticeCursor#"
              elseif args.lnum > vim.fn.line(".") then
                rel_hl = "%#LineJusticeRelBelow#"
              else
                rel_hl = "%#LineJusticeRelAbove#"
              end

              -- Format both numbers with thousands separators
              local abs_num = format_line_number(args.lnum)
              -- Cursor line: show no relative number (blank)
              local rel_num = args.relnum == 0 and "" or format_line_number(args.relnum)

              -- Calculate column width from total file line count
              local total_lines  = vim.fn.line("$")
              local num_d        = #tostring(total_lines)
              local num_c        = math.floor((num_d - 1) / 3)
              local line_num_w   = num_d + num_c

              -- Right-align the absolute number
              local abs_padding = string.rep(" ", math.max(0, line_num_w - #abs_num))
              abs_num = abs_padding .. abs_num

              -- Right-align the relative number so the total width stays fixed
              local target_w  = line_num_w + 1 + line_num_w
              local current_w = #abs_num + 1 + #rel_num
              local rel_padding = string.rep(" ", math.max(0, target_w - current_w))

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

-- ---------------------------------------------------------------------------
-- Treesitter context
-- ---------------------------------------------------------------------------

--- Setup treesitter context.
function M._setup_treesitter_context()
  local ok, treesitter_context = pcall(require, "treesitter-context")
  if not ok then
    vim.notify(
      "[line-justice] treesitter-context not found. " ..
      "Install nvim-treesitter-context to use this feature.",
      vim.log.levels.WARN
    )
    return
  end

  treesitter_context.setup({
    multiwindow  = config.treesitter_context.multiwindow,
    line_numbers = config.treesitter_context.line_numbers,
    separator    = config.treesitter_context.separator,
  })
end

-- ---------------------------------------------------------------------------
-- LSP
-- ---------------------------------------------------------------------------

--- Map from action name to the corresponding vim.lsp.buf function.
local lsp_actions = {
  hover           = function() vim.lsp.buf.hover() end,
  definition      = function() vim.lsp.buf.definition() end,
  references      = function() vim.lsp.buf.references() end,
  declaration     = function() vim.lsp.buf.declaration() end,
  type_definition = function() vim.lsp.buf.type_definition() end,
  implementation  = function() vim.lsp.buf.implementation() end,
  rename          = function() vim.lsp.buf.rename() end,
  code_action     = function() vim.lsp.buf.code_action() end,
  format          = function() vim.lsp.buf.format({ async = true }) end,
  signature_help  = function() vim.lsp.buf.signature_help() end,
}

--- Setup LSP via mason-lspconfig.
function M._setup_lsp()
  local ok_mason, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not ok_mason then
    vim.notify(
      "[line-justice] mason-lspconfig not found. " ..
      "Install mason-lspconfig.nvim to use LSP features.",
      vim.log.levels.WARN
    )
    return
  end

  mason_lspconfig.setup({
    ensure_installed = config.lsp.ensure_installed,
    automatic_enable = config.lsp.automatic_enable,
  })

  -- Attach keymaps when an LSP client connects
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LineJusticeLsp", { clear = true }),
    callback = function(args)
      local buf_opts = { buffer = args.buf, noremap = true, silent = true }

      -- config.lsp.keymaps = { action = "key" }, e.g. { hover = "K" }
      for action, key in pairs(config.lsp.keymaps) do
        local fn = lsp_actions[action]
        if fn then
          vim.keymap.set("n", key, fn, buf_opts)
        else
          vim.notify(
            "[line-justice] Unknown LSP keymap action: " .. tostring(action),
            vim.log.levels.WARN
          )
        end
      end
    end,
  })
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Setup function to initialise the plugin.
---@param opts table|nil User configuration options (merged with defaults)
function M.setup(opts)
  config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Core feature: dual line numbers via statuscol.nvim
  if config.statuscol.enabled then
    M._setup_statuscol()
  end

  -- Optional: treesitter context
  if config.treesitter_context.enabled then
    M._setup_treesitter_context()
  end

  -- Optional: LSP
  if config.lsp.enabled then
    M._setup_lsp()
  end
end

--- Return the current resolved configuration.
---@return table
function M.get_config()
  return config
end

return M

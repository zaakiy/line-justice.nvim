local M = {}

-- Default configuration
local defaults = {
  -- Core line number display
  line_numbers = {
    enabled = true,
    -- Width (in characters) reserved for absolute line numbers.
    -- 0 = auto-detect based on total line count.
    abs_width = 0,
    -- Width (in characters) reserved for relative line numbers.
    rel_width = 2,
    -- Separator string shown between absolute and relative columns.
    separator = " ",
    -- Highlight groups for each column.
    abs_hl = "LineNr",
    rel_hl = "LineNrAbove",
    cur_hl = "CursorLineNr",
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
-- Helpers
-- ---------------------------------------------------------------------------

--- Return the number of digits needed to represent `n`.
---@param n number
---@return number
local function num_digits(n)
  if n <= 0 then return 1 end
  return math.floor(math.log(n, 10)) + 1
end

--- Left-pad `s` with spaces to width `w`.
---@param s string
---@param w number
---@return string
local function lpad(s, w)
  local padding = w - #s
  if padding <= 0 then return s end
  return string.rep(" ", padding) .. s
end

-- ---------------------------------------------------------------------------
-- Statuscolumn builder
-- ---------------------------------------------------------------------------

--- Called once per rendered line by the statuscolumn expression.
--- Builds a string: <abs_number> <sep> <rel_number>
---@return string
function M._build_statuscol()
  local lnum    = vim.v.lnum    -- absolute line number of the rendered line
  local relnum  = vim.v.relnum  -- relative distance from cursor (0 = cursor line)
  local virtnum = vim.v.virtnum -- >0 for wrapped virtual lines, -1 for filler

  -- Don't render anything for virtual / filler lines
  if virtnum ~= 0 then
    return ""
  end

  local cfg = config.line_numbers

  -- Determine absolute column width
  local abs_w = cfg.abs_width
  if abs_w == 0 then
    abs_w = num_digits(vim.api.nvim_buf_line_count(0))
    if abs_w < 3 then abs_w = 3 end  -- minimum 3 chars so short files look tidy
  end

  local rel_w = cfg.rel_width

  -- Format each column
  local abs_str = lpad(tostring(lnum), abs_w)
  local rel_str, abs_hl_group, rel_hl_group

  if relnum == 0 then
    -- Cursor line: relative column is blank, absolute gets cursor highlight
    rel_str      = string.rep(" ", rel_w)
    abs_hl_group = cfg.cur_hl
    rel_hl_group = cfg.cur_hl
  else
    rel_str      = lpad(tostring(relnum), rel_w)
    abs_hl_group = cfg.abs_hl
    rel_hl_group = cfg.rel_hl
  end

  -- Build the statuscolumn string using %#HlGroup# syntax
  return "%#" .. abs_hl_group .. "#" .. abs_str
      .. "%#LineNr#" .. cfg.separator
      .. "%#" .. rel_hl_group .. "#" .. rel_str
      .. "%#Normal# "  -- trailing space + reset highlight
end

--- Apply the statuscolumn to all existing windows and set an autocmd so any
--- new window created later also gets it.
local function apply_statuscol()
  -- The expression calls back into Lua on every line render.
  local expr = "%!v:lua.require('line-justice')._build_statuscol()"

  -- Apply to all current windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.wo[win].statuscolumn = expr
  end

  -- Apply to future windows
  vim.api.nvim_create_autocmd({ "WinNew", "BufWinEnter" }, {
    group = vim.api.nvim_create_augroup("LineJusticeStatuscol", { clear = true }),
    callback = function()
      vim.wo.statuscolumn = expr
    end,
  })
end

-- ---------------------------------------------------------------------------
-- Treesitter context
-- ---------------------------------------------------------------------------

--- Setup treesitter context
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
  hover       = function() vim.lsp.buf.hover() end,
  definition  = function() vim.lsp.buf.definition() end,
  references  = function() vim.lsp.buf.references() end,
  declaration = function() vim.lsp.buf.declaration() end,
  type_definition = function() vim.lsp.buf.type_definition() end,
  implementation  = function() vim.lsp.buf.implementation() end,
  rename      = function() vim.lsp.buf.rename() end,
  code_action = function() vim.lsp.buf.code_action() end,
  format      = function() vim.lsp.buf.format({ async = true }) end,
  signature_help = function() vim.lsp.buf.signature_help() end,
}

--- Setup LSP configuration
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
    ensure_installed   = config.lsp.ensure_installed,
    automatic_enable   = config.lsp.automatic_enable,
  })

  -- Setup LSP keymaps on attach
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LineJusticeLsp", { clear = true }),
    callback = function(args)
      local buf_opts = { buffer = args.buf, noremap = true, silent = true }

      -- config.lsp.keymaps = { action = "key" },  e.g. { hover = "K" }
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

  -- Core feature: dual line numbers via statuscolumn
  if config.line_numbers.enabled then
    -- Ensure NeoVim's built-in line number display is off
    -- so our custom statuscol is the sole source of truth.
    vim.opt.number         = false
    vim.opt.relativenumber = false
    apply_statuscol()
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

--- Disable LineJustice and restore NeoVim defaults.
function M.disable()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.wo[win].statuscolumn = ""
  end
  vim.opt.number         = true
  vim.opt.relativenumber = false
  pcall(vim.api.nvim_del_augroup_by_name, "LineJusticeStatuscol")
end

--- Toggle LineJustice on/off.
function M.toggle()
  if config.line_numbers and config.line_numbers.enabled then
    M.disable()
    config.line_numbers.enabled = false
  else
    config.line_numbers = config.line_numbers or defaults.line_numbers
    config.line_numbers.enabled = true
    apply_statuscol()
  end
end

--- Return the current resolved configuration.
---@return table
function M.get_config()
  return config
end

return M

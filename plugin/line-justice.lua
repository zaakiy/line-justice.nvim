-- line-justice.nvim plugin entry point
-- This file is sourced automatically by NeoVim when the plugin is loaded.
-- It exposes user commands and defers setup to the user's config.

if vim.g.loaded_line_justice then
  return
end
if vim.fn.has("nvim-0.10") == 0 then
  vim.notify("[line-justice] Requires NeoVim 0.10+", vim.log.levels.ERROR)
  return
end
vim.g.loaded_line_justice = 1

-- User-facing commands
vim.api.nvim_create_user_command("LineJusticeToggle", function()
  require("line-justice").toggle()
end, { desc = "Toggle LineJustice dual line numbers" })

vim.api.nvim_create_user_command("LineJusticeDisable", function()
  require("line-justice").disable()
end, { desc = "Disable LineJustice and restore defaults" })

vim.api.nvim_create_user_command("LineJusticeEnable", function()
  local lj = require("line-justice")
  local cfg = lj.get_config()
  if not next(cfg) then
    lj.setup({})
  else
    lj.toggle()
  end
end, { desc = "Enable LineJustice dual line numbers" })

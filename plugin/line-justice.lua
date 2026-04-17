-- line-justice.nvim plugin entry point
-- Sourced automatically by NeoVim. Registers user commands and guards
-- against double-loading.

if vim.g.loaded_line_justice then
  return
end
if vim.fn.has("nvim-0.10") == 0 then
  vim.notify("[line-justice] Requires NeoVim 0.10+", vim.log.levels.ERROR)
  return
end
vim.g.loaded_line_justice = 1

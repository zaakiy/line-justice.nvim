-- Drop this into your lazy.nvim plugins directory, e.g.
-- ~/.config/nvim/lua/plugins/line-justice.lua

return {
  "zaakiy/line-justice.nvim",
  dependencies = { "luukvbaal/statuscol.nvim" },
  event = "VeryLazy",
  opts = {
    -- All options are optional. Defaults shown below.
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
      -- Uncomment to override auto-detected colours:
      -- highlights = {
      --   cursor    = { fg = "#bb9af7", bold = true },
      --   abs_above = { fg = "#565f89" },
      --   abs_below = { fg = "#41664f" },
      --   rel_above = { fg = "#7b9ac7" },
      --   rel_below = { fg = "#6aa781" },
      --   wrapped   = { fg = "#565f89", italic = true },
      -- },
    },
  },
}

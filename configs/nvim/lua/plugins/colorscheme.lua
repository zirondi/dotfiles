return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      italic_comments = true,
      hide_fillchars = true,
      borderless_telescope = true,
      overrides = function(colors)
        return {
          -- Fix the faded text on the selected line in the file explorer
          NeoTreeCursorLine = { bg = "#3C3F45", fg = "#FFFFFF", bold = true },
          CursorLine = { bg = "#3C3F45" },
          -- Brighten up git ignored/dimmed files so they don't fade into the blur
          NeoTreeDimText = { fg = "#C0C0C0" },
          NeoTreeGitIgnored = { fg = "#C0C0C0" },
          
          -- Force untracked (?), modified, and normal files to be extremely bright
          NeoTreeGitUntracked = { fg = "#FFFFFF", bold = true },
          NeoTreeGitModified = { fg = "#f1ff5e", bold = true },
          NeoTreeFileName = { fg = "#FFFFFF" },
          NeoTreeNormal = { fg = "#FFFFFF", bg = "NONE" },
          NeoTreeNormalNC = { fg = "#FFFFFF", bg = "NONE" },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "cyberdream",
    },
  },
}

vim.pack.add({
    { src = "https://github.com/folke/which-key.nvim" },
})

require("which-key").setup({
  ---@type false | "classic" | "modern" | "helix"
  preset = "modern",  -- 预设主题风格
})
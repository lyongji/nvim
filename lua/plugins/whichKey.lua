vim.pack.add({
    { src = "https://github.com/folke/which-key.nvim" },
})

require("which-key").setup({
  ---@type false | "classic" | "modern" | "helix"
  preset = "modern",  -- 预设主题风格
  spec = {
    { "<leader>f", group = "文件查找", icon = "󰈞 " },
    { "<leader>g", group = "Git", icon = "󰊢 " },
    { "<leader>b", group = "缓冲区", icon = "󰅩 " },
    { "<leader>l", group = "LSP", icon = "󰌘 " },
    { "<leader>t", group = "终端", icon = " " },
    { "<leader>x", group = "诊断/列表", icon = "󰌶 " },
  },
})

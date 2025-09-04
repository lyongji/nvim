return {
  {
    "folke/noice.nvim",
    -- stylua: ignore
  keys = {
    { "<leader>sn", "", desc = "+消息管理"},
    { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "重定向命令行" },
    { "<leader>snl", function() require("noice").cmd("last") end, desc = "上一条消息" },
    { "<leader>snh", function() require("noice").cmd("history") end, desc = "消息历史" },
    { "<leader>sna", function() require("noice").cmd("all") end, desc = "所有消息" },
    { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "清除所有消息" },
    { "<leader>snt", function() require("noice").cmd("pick") end, desc = "消息选择器 (Telescope/FzfLua)" },
    { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "向前滚动", mode = {"i", "n", "s"} },
    { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "向后滚动", mode = {"i", "n", "s"}},
  },
  },
}

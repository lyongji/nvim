return {
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "切换固定状态" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "删除未固定缓冲区" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "删除右侧缓冲区" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "删除左侧缓冲区" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个缓冲区" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "下一个缓冲区" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个缓冲区" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "下一个缓冲区" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "向前移动缓冲区" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "向后移动缓冲区" },
    },
  },
}

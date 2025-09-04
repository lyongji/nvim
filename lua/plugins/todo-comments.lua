return {

  {
    "folke/todo-comments.nvim",
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "下一个待办注释",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "上一个待办注释",
      },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "待办事项 (Trouble)" },
      {
        "<leader>xT",
        "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
        desc = "待办/修复/修复备注 (Trouble)",
      },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "待办事项" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "待办/修复/修复备注" },
    },
  },
}

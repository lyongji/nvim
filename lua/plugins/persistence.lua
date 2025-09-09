return {
  {
    "folke/persistence.nvim",
    keys = { -- 键位映射
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "恢复会话",
      }, -- 领导者键+qs：加载保存的会话
      {
        "<leader>qS",
        function()
          require("persistence").select()
        end,
        desc = "选择会话",
      }, -- 领导者键+qS：从列表中选择会话
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "恢复上一个会话",
      }, -- 领导者键+ql：加载最近一次会话
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "不保存当前会话",
      }, -- 领导者键+qd：停止持久化当前会话
    },
  },
}

return {
  {
    "folke/which-key.nvim",
    opts = {
      preset = "modern",
      spec = {
        {
          mode = { "n", "v" },
          { "<leader><tab>", group = "标签页" },
          { "<leader>c", group = "代码" },
          { "<leader>d", group = "调试" },
          { "<leader>dp", group = "性能分析" },
          { "<leader>f", group = "文件/查找" },
          { "<leader>g", group = "Git" },
          { "<leader>gh", group = "代码块" },
          { "<leader>q", group = "退出/会话" },
          { "<leader>s", group = "搜索" },
          { "<leader>u", group = "界面", icon = { icon = "󰙵 ", color = "cyan" } },
          { "<leader>x", group = "诊断/快速修复", icon = { icon = "󱖫 ", color = "green" } },
          { "[", group = "上一个" },
          { "]", group = "下一个" },
          { "g", group = "跳转" },
          { "gs", group = "环绕" },
          { "z", group = "折叠" },
          {
            "<leader>b",
            group = "缓冲区",
            expand = function()
              return require("which-key.extras").expand.buf()
            end,
          },
          {
            "<leader>w",
            group = "窗口",
            proxy = "<c-w>",
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          -- 更好的描述
          { "gx", desc = "用系统应用打开" },
        },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "缓冲区快捷键映射 (which-key)",
      },
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "窗口 Hydra 模式 (which-key)",
      },
    },
  },
}

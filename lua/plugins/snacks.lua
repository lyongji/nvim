return {
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          pick = function(cmd, opts)
            return LazyVim.pick(cmd, opts)()
          end,
          header = [[

██╗  ██╗   ██╗   ██╗
██║  ╚██╗ ██╔╝   ██║
██║   ╚████╔╝    ██║
██║    ╚██╔╝██   ██║
███████╗██║ ╚█████╔╝
╚══════╝╚═╝  ╚════╝ 

 ]],
        -- stylua: ignore
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "查找", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "新建", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "查找文本", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "最近文件", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "配置", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "恢复会话", section = "session" },
          { icon = " ", key = "x", desc = "Lazy 扩展", action = ":LazyExtras" },
          { icon = "󰒲 ", key = "l", desc = "Lazy 插件管理", action = ":Lazy" },
          { icon = " ", key = "q", desc = "退出", action = ":qa" },
        },
        },
      },
    },
     -- stylua: ignore
  keys = {
    { "<leader>n", function()
      if Snacks.config.picker and Snacks.config.picker.enabled then
        Snacks.picker.notifications()
      else
        Snacks.notifier.show_history()
      end
    end, desc = "通知历史" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "清除所有通知" },
    { "<leader>.", function() Snacks.scratch() end, desc = "切换临时缓冲区" }, -- 领导者键+.：打开/关闭临时缓冲区
    { "<leader>S", function() Snacks.scratch.select() end, desc = "选择临时缓冲区" }, -- 领导者键+S：选择临时缓冲区
    { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "性能分析临时缓冲区" }, -- 领导者键+dps：打开性能分析临时缓冲区
    },
  },
}

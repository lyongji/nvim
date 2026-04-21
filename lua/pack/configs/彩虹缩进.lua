-- === 彩虹缩进 ===

local P = { name = "indent-blankline.nvim" } -- 仓库名

-- 懒加载触发器：打开或新建文件时加载插件
vim.api.nvim_create_autocmd({
  "BufReadPost", -- 读取已有文件后
  "BufNewFile",  -- 新建文件时
}, {
  callback = function()
    PackUtils.load(P, function()
      -- 彩虹颜色列表（按缩进层级循环使用）
      local highlight = {
        "RainbowBlue",   -- 蓝色
        "RainbowViolet", -- 紫色
        "RainbowRed",    -- 红色
        "RainbowYellow", -- 黄色
        "RainbowGreen",  -- 绿色
        "RainbowOrange", -- 橙色
        "RainbowCyan",   -- 青色
      }

      local hooks = require("ibl.hooks")

      -- 在配色方案变更时重新注册高亮组，确保颜色始终生效
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })    -- 红色
        vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" }) -- 黄色
        vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })   -- 蓝色
        vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" }) -- 橙色
        vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })  -- 绿色
        vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" }) -- 紫色
        vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })   -- 青色
      end)

      -- 初始化缩进线插件
      require("ibl").setup({
        indent = {
          highlight = highlight, -- 使用彩虹颜色循环显示缩进线
        },
        exclude = {
          filetypes = { "dashboard" }, -- 仪表盘页面不显示缩进线
        },
      })
    end)
  end,
})

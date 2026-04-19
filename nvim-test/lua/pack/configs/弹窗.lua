-- === 弹窗消息 noice ===

local P = {
  name = "noice.nvim",
  deps = { "nui.nvim" }, -- 依赖的UI库
}

-- 比其他插件更早启动才能捕获错误、警告等信息，这里不配置懒加载
PackUtils.load(P, function()
  require("noice").setup({
    presets = {
      bottom_search = true,     -- 搜索时使用经典的底部命令行
      command_palette = true,   -- 将命令行和弹出菜单放在一起显示
      long_message_to_split = true, -- 长消息将发送到分割窗口中显示
      inc_rename = false,       -- 启用 inc-rename.nvim 的输入对话框
      lsp_doc_border = false,   -- 为悬停文档和签名帮助添加边框
    },
    -- 需要过滤的信息
    -- routes = {},
  })
end)

-- === 弹窗消息 noice ===

local P = {
	name = "mini.notify",
}

-- 比其他插件更早启动才能捕获错误、警告等信息，这里不配置懒加载
PackUtils.load(P, function()
	require("mini.notify").setup({
		-- LSP进度通知
		lsp_progress = {
			enable = false, -- LSP进度通知
		},
		-- 窗口配置
		window = {
			-- 浮动窗口配置
			config = {
				border = "rounded", -- 圆角边框
				zindex = 100, -- 层叠顺序
				focusable = false, -- 不可聚焦
				style = "minimal", -- 最小化样式
			},
			max_width_share = 0.4, -- 最大宽度占屏幕40%
			winblend = 20, -- 透明度
		},
	})
end)

vim.keymap.set("n", "<leader>n", function()
    require("mini.notify").show_history()
  end, { desc = "查看通知历史" })


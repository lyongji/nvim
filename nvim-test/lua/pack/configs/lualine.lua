-- === 底部状态栏 ===

local P = {
	name = "lualine.nvim",
	deps = {"nvim-tree/nvim-web-devicons",},
}
		PackUtils.load(P, function()
			-- ==================== 【魔法时刻：动态融合主题】 ====================
			-- 获取当前 Neovim 的真实背景色 (Normal 高亮组)
			local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
			-- 如果是透明背景，bg 返回 nil，我们赋值为 "NONE"；否则转换为 HEX 颜色码
			local editor_bg = normal_hl.bg and string.format("#%06x", normal_hl.bg) or "NONE"
			-- 加载 Lualine 的自动主题，它会自动为你提取当前主题的前景色(文字颜色)
			local blended_theme = require("lualine.themes.auto")
			-- 遍历主题的所有的模式 (normal, insert, visual...) 和区块 (a, b, c...)
			for _, mode in pairs(blended_theme) do
				for _, section in pairs(mode) do
					if type(section) == "table" then
						-- 强行将它们的背景色全部涂成和编辑器完全一样的颜色
						section.bg = editor_bg
					end
				end
			end
			-- ====================================================================
			require("lualine").setup({
				options = {
					-- 挂载我们刚刚特制的融合主题
					theme = blended_theme,
					-- 全局唯一状态栏 (不仅底部更干净，而且背景融合得更彻底)
					globalstatus = true,

					always_divide_middle = false,
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = {},
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { {
						"lsp_status",
						color = { fg = "#6C6E81" },
					}, },
					lualine_x = {},
					lualine_y = {},
					lualine_z = { "progress" },
				},
			})
		end)

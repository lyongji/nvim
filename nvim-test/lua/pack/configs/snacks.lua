-- === Snacks ===

local P = {
	name = "snacks.nvim",
}

PackUtils.load(P, function()
	require("snacks").setup({
		-- 通知器配置
		notifier = {}, -- 替代了folke/noice.nvim插件的rcarriga/nvim-notify依赖
		terminal = {
			win = {
				style = "terminal",
				size = { width = 0.8, height = 0.6 }, -- 浮动窗口尺寸
				border = "rounded", -- 边框样式
				title = "终端",
			},
			-- shell = "pwsh -NoLogo -NoProfile", -- 只在终端中用 pwsh
		},
		-- 选择器配置
		picker = {
			-- 匹配器设置：使用频率、当前目录和历史记录作为匹配依据
			matcher = { frecency = false, cwd_bonus = true, history_bonus = true },
			-- 格式化器设置：图标宽度为3个字符
			formatters = { icon_width = 3 },
			-- 窗口配置
			win = {
				input = {
					keys = {
						-- 注释掉的ESC关闭功能
						-- ["<Esc>"] = { "close", mode = { "n", "i" } },
						["<C-q>"] = { "close", mode = { "n", "i" } }, -- Ctrl+q 关闭功能
						-- Ctrl+t 在新标签页中编辑
						["<C-t>"] = { "edit_tab", mode = { "n", "i" } },
					},
				},
			},
		},
		-- 仪表板配置（已禁用）
		dashboard = {
			enabled = true,
			preset = {
				-- 仪表板快捷键预设
				keys = {
					-- { icon = "󰈞 ", key = "f", desc = "搜文件", action = ":lua Snacks.picker.smart()" },
					{ icon = " ", key = "e", desc = "新建文件", action = ":enew" },
					{ icon = " ", key = "o", desc = "最近文件", action = ":lua Snacks.picker.recent()" },
					{ icon = " ", key = "M", desc = "Mason", action = ":Mason" },
					{ icon = " ", key = "q", desc = "退出", action = ":qa" },
				},
				-- 仪表板头部ASCII艺术
				header = [[
  _____   ____  ____   _____
 |_   _| |_  _||_  _| |_   _|
   | |     \ \  / /     | |
   | |   _  \ \/ /  _   | |
  _| |__/ | _|  |_ | |__' |
 |________||______|`.____.'

]],
			},
			-- 仪表板部分布局
			sections = {
				{ section = "header" },
				{ icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
			},
		},
		-- 图像显示配置
		image = {
			enabled = true,
			doc = {
				enabled = true, -- 启用文档图像
				inline = false, -- 不内联显示
				float = false, -- 不使用浮动窗口
				max_width = 80, -- 最大宽度
				max_height = 20, -- 最大高度
			},
		},

		-- 缩进指南配置
		indent = {
			enabled = true,
			indent = { enabled = false },
			animate = { duration = { step = 10, duration = 100 } },
			scope = {
				enabled = true, -- 启用作用域显示
				char = "┊", -- 使用虚线字符
				underline = false, -- 不下划线
				only_current = true, -- 只显示当前作用域
				priority = 1000, -- 高优先级
			},
		},
		-- 样式配置
		styles = {
			snacks_image = {
				border = "rounded", -- 圆角边框
				backdrop = false, -- 无背景遮罩
			},
		},
	})
end)

-- 创建快捷键映射辅助函数
local map = function(key, func, desc)
	vim.keymap.set("n", key, func, { desc = desc })
end

-- [文件查找相关快捷键]
-- 查找最近文件
map("<leader>fo", Snacks.picker.recent, "查找最近文件")
-- 在帮助中查找（下拉布局）
map("<leader>fh", function()
	Snacks.picker.help({ layout = "dropdown" })
end, "帮助中查找")
-- 查找选择器布局
map("<leader>fl", Snacks.picker.picker_layouts, "查找选择器布局")
-- 查找快捷键映射（下拉布局）
map("<leader>fk", function()
	Snacks.picker.keymaps({ layout = "dropdown" })
end, "查找快捷键映射")
-- 查找缓冲区（按最后使用时间排序）
map("<leader><leader>", function()
	Snacks.picker.buffers({ sort_lastused = true })
end, "查找缓冲区")
-- 查找标记
map("<leader>fm", Snacks.picker.marks, "查找标记")
-- 查找通知（下拉布局）
map("<leader>fn", function()
	Snacks.picker.notifications({ layout = "dropdown" })
end, "查找通知")

-- [LSP相关快捷键]
-- 查找LSP引用
map("grr", Snacks.picker.lsp_references, "查找LSP引用")
-- 查找工作区符号
map("<leader>fS", Snacks.picker.lsp_workspace_symbols, "Find workspace symbol")
-- 查找当前缓冲区符号（智能选择LSP或Treesitter）
map("<leader>fs", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })

	-- 检查是否有LSP提供符号功能
	local function has_lsp_symbols()
		for _, client in ipairs(clients) do
			if client.server_capabilities.documentSymbolProvider then
				return true
			end
		end
		return false
	end

	-- 如果有LSP符号支持，使用LSP符号选择器，否则使用Treesitter
	if has_lsp_symbols() then
		Snacks.picker.lsp_symbols({
			layout = "dropdown",
			tree = true, -- 树状显示
			-- 显示时自动退出插入模式（注释掉的功能）
			-- on_show = function()
			--   vim.cmd.stopinsert()
			-- end,
		})
	else
		vim.notify("当前缓冲区没有 LSP 符号支持", vim.log.levels.WARN)
	end
end, "在当前缓冲区中查找符号")

-- [其他查找功能]
-- 查找图标
-- map("<leader>fi", Snacks.picker.icons, "查找图标")
-- 在当前缓冲区中查找行
map("<leader>fb", Snacks.picker.lines, "查找行:当前缓冲区")
-- 查找当前缓冲区的诊断信息
map("<leader>fd", Snacks.picker.diagnostics_buffer, "查找诊断信息:当前缓冲区")
-- 查找高亮组
map("<leader>fH", Snacks.picker.highlights, "查找高亮组")
-- 查找搜索历史
map("<leader>f/", Snacks.picker.search_history, "查找搜索历史")
-- 查找跳转历史
map("<leader>fj", Snacks.picker.jumps, "查找跳转历史")
-- 自定义查找：查找包含"FCN="的行
map("<leader>fF", function()
	Snacks.picker.lines({ search = "FCN=" })
end, "自定义查找")
-- Git集成
map("<leader>gg", function()
	Snacks.lazygit({ cwd = Snacks.git.get_root() }) -- 在git根目录打开lazygit
end, "打开 lazygit")
map("<leader>gb", Snacks.git.blame_line, "Git blame line") -- 行级git blame

-- 通知管理
map("<leader>n", Snacks.notifier.show_history, "通知历史记录")
map("<leader>N", Snacks.notifier.hide, "通知历史记录")

-- 图像显示
map("<leader>ki", Snacks.image.hover, "悬停时显示图像")

-- 打开/切换终端
map("<leader>tt", Snacks.terminal.open, "默认终端")

-- 根据屏幕大小动态调整
local function get_floating_config()
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	return {
		relative = "editor",
		width = math.min(120, math.floor(width * 0.9)),
		height = math.min(40, math.floor(height * 0.8)),
		row = math.floor((height - 40) * 0.5),
		col = math.floor((width - 120) * 0.5),
		border = "single",
		title = { { " 浮动终端 ", "Title" } },
	}
end

vim.keymap.set("n", "<leader>tT", function()
	-- 使用动态配置
	Snacks.terminal("cmd", { win = get_floating_config() })
end, { desc = "打开浮动终端" })

vim.keymap.set("n", "<leader>tm", function()
	-- 使用动态配置
	Snacks.terminal("cmd", {
		win = {
			relative = "cursor",
			width = 60,
			height = 15,
			row = 1, -- 光标下方
			col = 0,
			border = "single",
			title = "快速执行",
		},
		auto_close = true,
	})
end, { desc = "打开快速终端" })

-- 终端内操作
vim.keymap.set("t", "<C-q>", "<Cmd>stopinsert<CR>", { desc = "退出终端插入" })

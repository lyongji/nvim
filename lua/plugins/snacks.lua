-- 添加 snacks.nvim 插件
vim.pack.add({
	{ src = "https://github.com/folke/snacks.nvim", name = "snacks" },
})

-- 设置 snacks 插件配置
require("snacks").setup({
	-- 通知器配置
	notifier = {},
	-- 选择器配置
	picker = {
		-- 匹配器设置：使用频率、当前目录和历史记录作为匹配依据
		matcher = { frecency = true, cwd_bonus = true, history_bonus = true },
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
				{ icon = "󰈞 ", key = "f", desc = "搜文件", action = ":lua Snacks.picker.smart()" },
				-- { icon = " ", key = "o", desc = "搜历史记录", action = "lua Snacks.picker.recent()" },
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
		enabled = false,
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

-- 创建快捷键映射辅助函数
local map = function(key, func, desc)
	vim.keymap.set("n", key, func, { desc = desc })
end

-- [文件查找相关快捷键]
-- 智能文件查找
map("<leader>ff", Snacks.picker.smart, "查找文件")
-- 查找最近文件
map("<leader>fo", Snacks.picker.recent, "查找最近文件")
-- 查找文件内容
map("<leader>fw", Snacks.picker.grep, "查找文件内容")
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
map("grr", Snacks.picker.lsp_references, "Find lsp references")
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
		Snacks.picker.treesitter()
	end
end, "在当前缓冲区中查找符号")

-- [其他查找功能]
-- 查找图标
map("<leader>fi", Snacks.picker.icons, "查找图标")
-- 在当前缓冲区中查找行
map("<leader>fb", Snacks.picker.lines, "查找行:当前缓冲区")
-- 查找当前缓冲区的诊断信息
map("<leader>fd", Snacks.picker.diagnostics_buffer, "查找诊断信息:当前缓冲区")
-- 查找高亮组
map("<leader>fH", Snacks.picker.highlights, "查找高亮组")
-- 查找Neovim配置文件
map("<leader>fc", function()
	Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, "查找Neovim配置文件")
-- 查找搜索历史
map("<leader>f/", Snacks.picker.search_history, "查找搜索历史")
-- 查找跳转历史
map("<leader>fj", Snacks.picker.jumps, " 查找跳转历史")

-- [TODO和任务查找]
-- 智能TODO查找：在markdown中查找任务列表，在其他文件中查找代码注释
map("<leader>ft", function()
	if vim.bo.filetype == "markdown" then
		-- Markdown模式：查找未完成的任务（- [ ] 格式）
		Snacks.picker.grep_buffers({
			finder = "grep",
			format = "file",
			prompt = " ",
			search = "^\\s*- \\[ \\]", -- 匹配 - [ ] 模式
			regex = true,
			live = false,
			args = { "--no-ignore" }, -- 忽略.gitignore设置
			on_show = function()
				vim.cmd.stopinsert() -- 显示时退出插入模式
			end,
			buffers = false,
			supports_live = false,
			layout = "ivy", -- 使用ivy布局
		})
	else
		-- 其他文件类型：查找代码中的TODO注释
		Snacks.picker.todo_comments({
			keywords = { "NOTE", "TODO", "FIX", "FIXME", "HACK" },
			layout = "select",
		})
	end
end, "Find todo")

-- 自定义查找：查找包含"FCN="的行
map("<leader>fF", function()
	Snacks.picker.lines({ search = "FCN=" })
end)

-- [其他snacks功能]
-- 缓冲区管理
map("<leader>bc", Snacks.bufdelete.delete, "删除缓冲区")
map("<leader>bC", Snacks.bufdelete.other, "删除其他缓冲区")

-- Git集成
map("<leader>gg", function()
	Snacks.lazygit({ cwd = Snacks.git.get_root() }) -- 在git根目录打开lazygit
end, "打开 lazygit")
map("<leader>gb", Snacks.git.blame_line, "Git blame line") -- 行级git blame

-- 通知管理
map("<leader>n", Snacks.notifier.show_history, "通知历史记录")
map("<leader>N", Snacks.notifier.hide, "通知历史记录")

-- 图像显示
map("<leader>K", Snacks.image.hover, "悬停时显示图像")

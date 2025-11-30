-- 使用 Neovim 内置包管理器添加 Catppuccin 主题插件
-- 注意：这行代码可能不适用于所有插件管理器，通常使用 Packer/Lazy 等
vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim" },  -- 从 GitHub 直接添加 Catppuccin 主题
})

-- 配置 Catppuccin 主题
require("catppuccin").setup({
	-- 透明背景设置
	transparent_background = true,  -- 启用透明背景
	
	-- 终端颜色设置
	term_colors = true,  -- 在终端中设置主题颜色
	
	-- 集成插件配置
	integrations = {
		aerial = true,      -- 支持 aerial 代码轮廓插件
		diffview = true,    -- 支持 diffview 差异查看插件
		mini = {            -- 支持 mini.nvim 插件集
			enabled = true,
			indentscope_color = "sky",  -- 缩进范围指示器颜色
		},
		noice = true,       -- 支持 noice.nvim 通知UI插件
		-- overseer = true,  -- 任务运行器支持（已注释）
		telescope = {       -- 支持 telescope 模糊查找
			enabled = true,
			-- style = "nvchad",  -- 可选的 telescope 样式（已注释）
		},
		treesitter = true,  -- 支持 treesitter 语法高亮
		notify = true,      -- 支持 notify 通知系统
		gitsigns = true,    -- 支持 gitsigns Git 状态显示
		flash = true,       -- 支持 flash.nvim 快速跳转
		blink_cmp = true,   -- 支持 blink-cmp 补全插件
		mason = true,       -- 支持 mason 包管理器
		snacks = true,      -- 支持 snacks 插件（可能是自定义插件）
	},
	
	-- 高亮组覆盖配置（针对 mocha 风味）
	highlight_overrides = {
		mocha = function(mocha)
			return {
				-- 光标行号高亮
				CursorLineNr = { fg = mocha.yellow },
				
				-- Telescope 选择相关高亮
				TelescopeSelection = { bg = mocha.surface0 },           -- 选择项背景
				TelescopeSelectionCaret = { fg = mocha.yellow, bg = mocha.surface0 },  -- 选择项光标
				TelescopePromptPrefix = { fg = mocha.yellow },          -- 提示前缀
				
				-- Flash 插件高亮配置
				FlashCurrent = { bg = mocha.peach, fg = mocha.base },   -- 当前匹配项
				FlashMatch = { bg = mocha.red, fg = mocha.base },       -- 匹配项
				FlashLabel = { bg = mocha.teal, fg = mocha.base },      -- 标签
				
				-- 浮动窗口相关高亮
				NormalFloat = { bg = mocha.base },      -- 浮动窗口背景
				FloatBorder = { bg = mocha.base },      -- 浮动窗口边框
				FloatTitle = { bg = mocha.base },       -- 浮动窗口标题
				
				-- Markdown 代码块高亮
				RenderMarkdownCode = { bg = mocha.crust },  -- Markdown 代码块背景
				
				-- 补全菜单高亮
				Pmenu = { bg = mocha.base },            -- 补全菜单背景
			}
		end,
	},
})

-- 应用 Catppuccin 颜色方案
vim.cmd("colorscheme catppuccin")

-- 设置状态线背景为透明
vim.cmd.hi("statusline guibg=NONE")

-- 设置注释样式（去除斜体）
vim.cmd.hi("Comment gui=none")
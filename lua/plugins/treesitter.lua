vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

vim.api.nvim_create_autocmd("BufReadPre", {
	group = vim.api.nvim_create_augroup("SetupTreesitter", { clear = true }),
	once = true, -- 只执行一次，避免重复设置
	callback = function()
		---@diagnostic disable-next-line: missing-fields
		require("nvim-treesitter.configs").setup({
			-- 确保安装的语言解析器
			ensure_installed = {
				"lua",
				-- 'python',
				--   'json',
				"markdown",
				"c",
				"cpp",
				--   'nim',
			}, -- 安装的语言,
			-- 忽略安装的语言解析器
			ignore_install = {
				"latex", -- LaTeX（可能因为大小或性能问题忽略）
				"yaml", -- YAML 文件
				"xml", -- XML 文件
			},
			auto_install = true, -- 自动安装缺失的语言解析器
			highlight = {
				enable = true, -- 启用语法高亮
				disable = { "latex" }, -- 禁用 LaTeX 的高亮
				-- 额外的 Vim 正则表达式高亮（用于 Ruby 等语言）
				additional_vim_regex_highlighting = { "ruby" },
			},
			-- 根据语言和缓冲区条件禁用 Treesitter
			disable = function(lang, bufnr)
				-- 如果是 YAML 文件且行数超过 5000 行，则禁用 Treesitter（性能优化）
				return lang == "yaml" and vim.api.nvim_buf_line_count(bufnr) > 5000
			end,
			indent = {
				enable = true, -- 启用基于 Treesitter 的智能缩进
				disable = { "ruby" }, -- 禁用 Ruby 的智能缩进（可能因为缩进规则复杂）
			},
		})
	end,
})


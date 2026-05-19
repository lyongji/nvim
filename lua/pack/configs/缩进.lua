-- === 彩虹缩进 ===

local P = { name = "mini.indentscope" } -- 仓库名

-- 懒加载触发器：打开或新建文件时加载插件
vim.api.nvim_create_autocmd({
	"BufReadPost", -- 读取已有文件后
	"BufNewFile", -- 新建文件时
}, {
	callback = function()
		PackUtils.load(P, function()
			require("mini.indentscope").setup({
				-- 绘制选项
				draw = {
					-- 事件与开始绘制作用域指示器之间的延迟（单位：毫秒）
					delay = 100,
					-- 作用域首次绘制的动画规则。一个函数，接收下一步编号和总步数，
					-- 返回等待时间（单位：毫秒）。内置选项请参阅 |MiniIndentscope.gen_animation|。
          -- animation = --<function: implements constant 20ms between steps>,
					-- 若要禁用动画，请使用 require('mini.indentscope').gen_animation.none()。
					-- 是否自动绘制作用域：返回 true 则绘制，false 则不绘制。
					-- 默认仅绘制完全计算出的作用域（参见 options.n_lines）。
					predicate = function(scope)
						return not scope.body.is_incomplete
					end,
					-- 符号优先级。增加该值以使符号显示在更多其他符号之上。
					priority = 2,
				},
				-- 模块映射。使用 ''（空字符串）来禁用某个映射。
				mappings = {
					-- 文本对象
					object_scope = "ii",
					object_scope_with_border = "ai",
					-- 移动操作（跳转到对应的边界行；如果不存在则跳转到主体行）
					goto_top = "[i",
					goto_bottom = "]i",
				},
				-- 控制作用域计算的选项
				options = {
					-- 作用域边界的类型：将缩进更小的哪些行归类为边界。
					-- 可选值: 'both', 'top', 'bottom', 'none'。
					border = "both",
					-- 计算参考缩进时是否使用光标列。
					-- 有助于通过水平光标移动查看渐进式的作用域。
					indent_at_cursor = true,
					-- 计算作用域时，光标上方或下方考虑的最大行数
					n_lines = 10000,
					-- 是否首先检查输入行是否为相邻作用域的边界。
					-- 若希望将光标置于函数头部以获取其函数体的作用域，请启用此选项。
					try_as_border = false,
				},
				-- 用于绘制作用域指示器的字符
				symbol = "╎",
			})
		end)
	end,
})

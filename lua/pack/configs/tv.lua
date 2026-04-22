-- === television 模糊查找 ===
-- tv.nvim 是 television 命令行工具的 Neovim 前端
-- 依赖：需要安装 television 二进制 (scoop install television)
-- 用途：替代 Snacks picker 中依赖 fd 的文件查找和内容搜索功能

local P = { name = "tv.nvim" }

-- 加载标志，确保插件只初始化一次
-- 避免每次按快捷键都重复执行 setup
local loaded = false

-- 懒加载函数：首次调用时加载并配置插件
local function ensure_loaded()
	if loaded then
		return
	end
	loaded = true

	PackUtils.load(P, function()
		-- handlers 提供了预定义的操作函数
		-- 比如打开文件、分屏打开、发送到 quickfix 等
		local h = require("tv").handlers
		-- 包装 handler：打开文件后触发 BufReadPost 让 LSP 加载
		local function with_lsp(handler)
			return function(entries, config)
				handler(entries, config)
				vim.schedule(function()
					vim.api.nvim_exec_autocmds("BufReadPost", { modeline = false })
				end)
			end
		end
		require("tv").setup({
			-- 浮动窗口外观配置
			window = {
				width = 0.8, -- 占编辑器宽度的 80%
				height = 0.8, -- 占编辑器高度的 80%
				border = "rounded", -- 圆角边框
				title = " Television ",
				title_pos = "center", -- 标题居中
			},

			-- 频道配置
			-- 每个频道对应一种搜索模式，类似 Telescope 的 picker
			channels = {

				-- git-files 频道：在 git 仓库中查找被追踪的文件
				-- 优点：自动排除 .gitignore 中的文件，速度更快
				["git-files"] = {
					handlers = {
						["<CR>"] = with_lsp(h.open_as_files), -- 回车：打开选中的文件
						["<C-s>"] = with_lsp(h.open_in_split), -- Ctrl+s：水平分屏打开
						["<C-v>"] = with_lsp(h.open_in_vsplit), -- Ctrl+v：垂直分屏打开
						["<C-f>"] = h.send_to_quickfix, -- Ctrl+q：发送到 quickfix 列表
						["<C-y>"] = h.copy_to_clipboard, -- + 复制路径
					},
				},

				-- files 频道：在任意目录中查找文件
				-- 用于非 git 仓库的项目
				files = {
					handlers = {
						["<CR>"] = with_lsp(h.open_as_files),
						["<C-s>"] = with_lsp(h.open_in_split),
						["<C-v>"] = with_lsp(h.open_in_vsplit),
						["<C-f>"] = h.send_to_quickfix,
						["<C-y>"] = h.copy_to_clipboard,
					},
				},

				-- text 频道：通过 ripgrep 搜索文件内容
				-- 类似 Snacks.picker.grep / Telescope live_grep
				text = {
					handlers = {
						["<CR>"] = with_lsp(h.open_at_line), -- 回车：跳转到匹配的行和列
						["<C-s>"] = with_lsp(h.open_in_split),
						["<C-v>"] = with_lsp(h.open_in_vsplit),
						["<C-f>"] = h.send_to_quickfix, -- 多个匹配结果发送到 quickfix 批量处理
						["<C-y>"] = h.copy_to_clipboard,
					},
				},
				-- + 环境变量搜索（插入到代码中）
				env = {
					handlers = {
						["<CR>"] = h.insert_at_cursor, -- 插入到光标位置
						["<C-l>"] = h.insert_on_new_line, -- 插入到新行
						["<C-y>"] = h.copy_to_clipboard,
					},
				},
			},
			-- quickfix 配置
			quickfix = {

				auto_open = true, -- Ctrl+q 发送后自动打开 quickfix 窗口
			},
		})
	end)
end

-- =========================================================================
-- 快捷键映射
-- =========================================================================

-- <leader>ff - 智能文件查找
-- 检测当前目录是否是 git 仓库：
--   是 → 使用 git-files（更快，自动排除 .gitignore）
--   否 → 使用 files（遍历所有文件）
vim.keymap.set({ "n", "x" }, "<leader>ff", function()
	ensure_loaded()
	local channel = vim.fs.root(0, ".git") and "git-files" or "files"
	vim.cmd("Tv " .. channel)
end, { desc = "查找文件（智能）" })

-- <leader>fw - 文件内容搜索
-- 使用 ripgrep 在所有文件中搜索文本
-- 支持正则表达式，实时预览匹配结果
vim.keymap.set({ "n", "x" }, "<leader>fw", function()
	ensure_loaded()
	vim.cmd("Tv text")
end, { desc = "查找文件内容" })
-- + 环境变量搜索
vim.keymap.set("n", "<leader>fe", function()
	ensure_loaded()
	vim.cmd("Tv env")
end, { desc = "搜索环境变量" })

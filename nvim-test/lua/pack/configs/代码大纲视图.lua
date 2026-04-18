-- === outline大纲 ===
-- === 代码大纲视图 ===

local P = {
	name = "outline.nvim",
}

vim.keymap.set({ "n", "x" }, "<leader>cv", function()
	PackUtils.load(P, function()
		require("outline").setup({
			outline_window = {
				position = "left",    -- 位置：左侧
				width = 20,           -- 宽度：20
			},
			keymaps = {
				show_help = "?",                      -- 显示帮助
				close = { "<Esc>", "q" },             -- 关闭窗口
				-- 跳转到光标下的符号。
				-- 触发时可以自动关闭大纲窗口，参见上面的 'auto_close' 选项
				goto_location = "<Cr>",               -- 跳转到符号位置
				-- 跳转到光标下的符号，但保持焦点在大纲窗口
				peek_location = "o",                  -- 预览符号位置
				-- 跳转到代码位置并立即关闭大纲窗口
				goto_and_close = "<S-Cr>",            -- 跳转并关闭
				-- 移动大纲窗口光标位置以匹配当前代码中的位置
				-- 与 goto/peek_location 相反的操作
				restore_location = "<C-g>",           -- 恢复光标位置
				-- 打开 LSP/提供器相关的符号悬停信息
				hover_symbol = "<C-space>",           -- 悬停查看符号信息
				-- 预览光标下符号的代码位置
				toggle_preview = "K",                 -- 切换预览
				rename_symbol = "r",                  -- 重命名符号
				code_actions = "a",                   -- 代码操作
				-- 以下折叠操作是折叠树节点，不是代码折叠
				fold = "n",                           -- 折叠节点
				unfold = "i",                         -- 展开节点
				fold_toggle = "<Tab>",                -- 切换折叠/展开
				-- 切换所有节点的折叠状态。
				-- 如果至少有一个节点被折叠，此操作将折叠所有节点。
				-- 如果所有节点都被折叠，此操作将展开所有节点。
				fold_toggle_all = "<S-Tab>",          -- 全部切换折叠
				fold_all = "N",                       -- 全部折叠
				unfold_all = "I",                     -- 全部展开
				fold_reset = "R",                     -- 重置折叠
				-- 向下/向上移动一行并立即预览位置。
				-- 你也可以使用 outline_window.auto_jump=true 来实现相同效果，
				-- 这适用于 j/k/<down>/<up> 键
				down_and_jump = "<C-e>",              -- 向下并跳转
				up_and_jump = "<C-u>",                -- 向上并跳转
			},
		})
	end)
	vim.cmd("Outline")  -- 打开大纲窗口
end, { desc = "切换大纲视图" })

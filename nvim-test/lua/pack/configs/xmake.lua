-- 快捷键表
local P = {
	name = "xmake.nvim",
}

vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("XmakeSetup", { clear = true }),
	pattern = "*/xmake.lua",
	callback = function()
		PackUtils.load(P, function()
			-- 首次加载插件
			require("xmake").setup({ lsp = { language = "zh-cn" } })
			-- 每个 xmake.lua 缓冲区都禁用自动格式化
			vim.b.autoformat = false
		end)
	end,
})

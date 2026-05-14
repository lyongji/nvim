----------------------
-- 自动命令 --
----------------------
-- 保存前自动格式化
-- vim.api.nvim_create_autocmd("BufWritePre", {
-- 	callback = function()
-- 		-- 如果当前 buffer 被标记为不自动格式化，则直接跳过
-- 		if vim.b.autoformat == false then
-- 			return
-- 		end
-- 		vim.lsp.buf.format()
-- 	end,
-- 	pattern = "*",
-- })
-- vim.treesitter.language.add('nim', { path = './parser/nim.dll' })
vim.treesitter.language.register("nim", { "nim", "nimble", "nims" })
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	pattern = { "*.nim", "*.nimble", "*.nims" },
	callback = function()
		vim.treesitter.start(0, "nim")
	end,
})

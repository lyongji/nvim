vim.pack.add({
	{ src = "https://github.com/linrongbin16/lsp-progress.nvim" , name = "lsp-progress"},
	{ src = "https://github.com/rebelot/heirline.nvim" , name = "heirline"},
})
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = vim.api.nvim_create_augroup("SetupHeirline", { clear = true }),
	once = true,
	callback = function()
		require("lsp-progress").setup()
		require("heirline").setup({
			statusline = require("config.状态线.statusline"),
		})
	end,
})
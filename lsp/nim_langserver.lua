return {
	cmd = { "nimlangserver.exe" },
	filetypes = { "nim", "nims", "nimble" },
	root_markers = { "*.nimble", "nim.cfg", ".git" },
	single_file_support = true,
	settings = {
		nim = {
			nimsuggestPath = "C:\\Users\\yongji.luo\\.nimble\\pkgs2\\nim-2.2.10-17ec440fdb89f8903db29a17898af590087d2b64\\bin\\nimsuggest.exe",
			inlayHints = {
				-- 暂时关闭所有 inlay hints 功能以减少崩溃可能
				typeHints = false,
				parameterHints = false,
				exceptionHints = false,
			},
			-- 禁用自动检查功能
			useNimCheck = false,
		},
	},
}

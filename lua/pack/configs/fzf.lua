-- === 使用 fzf-lua 替换 Snacks.nvim (智能工具检测版) ===
local P = {
	name = "ibhagwan/fzf-lua",
	deps = { "nvim-tree/nvim-web-devicons" },
}

PackUtils.load(P, function()
	local fzf = require("fzf-lua")
	local actions = fzf.actions

	-- 检查系统是否安装了指定工具
	local function has_tool(tool)
		return vim.fn.executable(tool) == 1
	end

	-- 智能选择文件搜索工具
	local function smart_file_cmd()
		if has_tool("fd") then
			return nil
		elseif has_tool("rg") then
			return nil
		else
			return "find . -type f"
		end
	end

	-- 智能选择搜索工具
	local function smart_search_cmd()
		if has_tool("rg") then
			return nil
		else
			return "grep -rn --color=auto"
		end
	end

	local file_cmd = smart_file_cmd()
	local search_cmd = smart_search_cmd()
	local rg_search_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096"

	-- ★★★ 核心修复：包装 action，打开文件后触发 LSP / Treesitter ★★★
	local function file_edit_and_reload(selected, opts)
		actions.file_edit(selected, opts)
		vim.schedule(function()
			local buf = vim.api.nvim_get_current_buf()
			local name = vim.api.nvim_buf_get_name(buf)
			if name == "" then
				return
			end
			-- 重新触发 filetype 检测 → 启动 LSP + treesitter 高亮
			vim.cmd("filetype detect")
			-- 触发 BufReadPost 让延迟加载的插件响应
			pcall(vim.api.nvim_exec_autocmds, "BufReadPost", {
				buffer = buf,
				modeline = false,
			})
			-- 强制刷新语法高亮
			if vim.treesitter and vim.treesitter.start then
				pcall(vim.treesitter.start, buf)
			end
		end)
	end

	-- 同样包装 split / vsplit / tabedit
	local function file_split_and_reload(selected, opts)
		actions.file_split(selected, opts)
		vim.schedule(function()
			vim.cmd("filetype detect")
			pcall(vim.api.nvim_exec_autocmds, "BufReadPost", {
				buffer = vim.api.nvim_get_current_buf(),
				modeline = false,
			})
		end)
	end

	local function file_vsplit_and_reload(selected, opts)
		actions.file_vsplit(selected, opts)
		vim.schedule(function()
			vim.cmd("filetype detect")
			pcall(vim.api.nvim_exec_autocmds, "BufReadPost", {
				buffer = vim.api.nvim_get_current_buf(),
				modeline = false,
			})
		end)
	end

	local function file_tabedit_and_reload(selected, opts)
		actions.file_tabedit(selected, opts)
		vim.schedule(function()
			vim.cmd("filetype detect")
			pcall(vim.api.nvim_exec_autocmds, "BufReadPost", {
				buffer = vim.api.nvim_get_current_buf(),
				modeline = false,
			})
		end)
	end

	-- 通用 action 表（会触发 LSP + 高亮）
	local file_actions = {
		["enter"] = file_edit_and_reload,
		["ctrl-s"] = file_split_and_reload,
		["ctrl-v"] = file_vsplit_and_reload,
		["ctrl-t"] = file_tabedit_and_reload,
		["alt-q"] = actions.file_sel_to_qf,
	}

	-- grep 用的 action 表（多一个切换搜索模式）
	local grep_actions = {
		["enter"] = file_edit_and_reload,
		["ctrl-s"] = file_split_and_reload,
		["ctrl-v"] = file_vsplit_and_reload,
		["ctrl-t"] = file_tabedit_and_reload,
		["alt-q"] = actions.file_sel_to_qf,
		["ctrl-g"] = { actions.grep_lgrep },
	}

	-- 检测并通知用户使用的工具
	local function notify_tools()
		local tools = {}
		local checks = {
			{ "fzf", "fzf" },
			{ "rg", "ripgrep" },
			{ "fd", "fd" },
			{ "bat", "bat" },
			{ "grep", "grep" },
			{ "find", "find" },
		}
		for _, item in ipairs(checks) do
			local cmd, name = item[1], item[2]
			table.insert(tools, name .. (has_tool(cmd) and " ✓" or " ✗"))
		end
		vim.notify("使用工具: " .. table.concat(tools, ", "), vim.log.levels.INFO)
	end

	vim.schedule(notify_tools)

	fzf.setup({
		-- ==================== 全局配置 ====================
		winopts = {
			height = 0.85,
			width = 0.80,
			row = 0.35,
			col = 0.50,
			border = "rounded",
			backdrop = 60,
			preview = {
				border = "rounded",
				wrap = false,
				hidden = false,
				vertical = "down:45%",
				horizontal = "right:60%",
				layout = "flex",
				flip_columns = 100,
				title = true,
				title_pos = "center",
				scrollbar = "float",
				scrolloff = -1,
				delay = 20,
				default = has_tool("bat") and "bat" or "cat",
				winopts = {
					number = true,
					relativenumber = false,
					cursorline = true,
					cursorlineopt = "both",
					foldenable = false,
				},
			},
		},

		-- ==================== 键位映射 ====================
		keymap = {
			builtin = {
				["<F1>"] = "toggle-help",
				["<F2>"] = "toggle-fullscreen",
				["<F3>"] = "toggle-preview-wrap",
				["<F4>"] = "toggle-preview",
			},
			fzf = {
				["ctrl-z"] = "abort",
				["ctrl-u"] = "unix-line-discard",
				["ctrl-f"] = "half-page-down",
				["ctrl-b"] = "half-page-up",
			},
		},

		-- ==================== 全局 action ====================
		actions = {
			files = file_actions,
		},

		-- ==================== fzf 选项 ====================
		fzf_opts = {
			["--ansi"] = true,
			["--info"] = "inline-right",
			["--height"] = "100%",
			["--layout"] = "reverse",
			["--border"] = "none",
			["--highlight-line"] = true,
			["--preview-window"] = "right:60%:border-rounded",
		},

		fzf_colors = true,

		-- ==================== 预览器配置 ====================
		previewers = {
			bat = {
				cmd = "bat",
				args = "--color=always --style=numbers,changes --line-range=:500",
				theme = "ansi",
			},
			cat = {
				cmd = "cat",
				args = "-n",
			},
		},

		-- ==================== 文件查找 ====================
		files = {
			prompt = "📁 文件: ",
			multiprocess = true,
			file_icons = true,
			color_icons = true,
			hidden = true,
			follow = false,
			cmd = file_cmd,
			fd_opts = has_tool("fd") and [[--color=never --type f --type l]] or nil,
			rg_opts = has_tool("rg") and [[--color=never --files]] or nil,
			find_opts = not has_tool("fd") and not has_tool("rg") and [[-type f]] or nil,
			previewer = has_tool("bat") and "bat" or "cat",
			actions = file_actions,
		},

		-- ==================== 最近文件 ====================
		oldfiles = {
			prompt = "🕐 最近文件: ",
			cwd_only = false,
			stat_file = true,
			include_current_session = false,
			ignore_current_buffer = true,
			previewer = has_tool("bat") and "bat" or "cat",
			actions = file_actions,
		},

		-- ==================== 帮助 ====================
		helptags = {
			prompt = "📚 帮助: ",
			previewer = has_tool("bat") and "bat" or "cat",
		},

		-- ==================== 缓冲区 ====================
		buffers = {
			prompt = "📄 缓冲区: ",
			file_icons = true,
			color_icons = true,
			sort_lastused = true,
			show_unloaded = true,
			previewer = has_tool("bat") and "bat" or "cat",
			actions = {
				["enter"] = file_edit_and_reload,
				["ctrl-s"] = file_split_and_reload,
				["ctrl-v"] = file_vsplit_and_reload,
				["ctrl-t"] = file_tabedit_and_reload,
				["ctrl-x"] = { fn = actions.buf_del, reload = true },
			},
		},

		-- ==================== 标记 ====================
		marks = {
			prompt = "📍 标记: ",
		},

		-- ==================== 键位映射 ====================
		keymaps = {
			prompt = "⌨️ 键位: ",
			winopts = { preview = { layout = "vertical" } },
			show_desc = true,
			show_details = true,
		},

		-- ==================== 实时搜索 ====================
		live_grep = {
			prompt = "🔍 实时搜索: ",
			multiprocess = true,
			file_icons = true,
			color_icons = true,
			cmd = search_cmd,
			rg_opts = has_tool("rg") and rg_search_opts or nil,
			grep_opts = not has_tool("rg")
					and "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp"
				or nil,
			previewer = has_tool("bat") and "bat" or "cat",
			actions = grep_actions,
		},

		-- ==================== 静态搜索 ====================
		grep = {
			prompt = "🔎 文本: ",
			input_prompt = "搜索内容: ",
			multiprocess = true,
			file_icons = true,
			color_icons = true,
			cmd = search_cmd and search_cmd .. " -e" or nil,
			rg_opts = has_tool("rg") and rg_search_opts .. " -e" or nil,
			grep_opts = not has_tool("rg")
					and "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e"
				or nil,
			previewer = has_tool("bat") and "bat" or "cat",
			actions = grep_actions,
		},

		-- ==================== 当前缓冲区搜索 ====================
		grep_curbuf = {
			prompt = "📄 当前缓冲区搜索: ",
			multiprocess = true,
			file_icons = true,
			color_icons = true,
			rg_opts = has_tool("rg") and rg_search_opts or nil,
			grep_opts = not has_tool("rg") and "--binary-files=without-match --line-number --color=auto --perl-regexp"
				or nil,
			previewer = has_tool("bat") and "bat" or "cat",
			actions = file_actions,
		},

		-- ==================== 当前文件内搜索(按行) ====================
		blines = {
			prompt = "📝 文件内搜索(行): ",
			file_icons = true,
			show_bufname = false,
			actions = {
				["enter"] = actions.file_edit,
			},
		},

		-- ==================== 所有打开文件搜索(按行) ====================
		lines = {
			prompt = "📚 所有文件搜索(行): ",
			file_icons = true,
			show_bufname = true,
			sort_lastused = true,
			actions = file_actions,
		},

		-- ==================== LSP 配置 ====================
		lsp = {
			references = {
				prompt = "🏷️ LSP 引用: ",
				file_icons = true,
				color_icons = true,
				jump1 = true,
				includeDeclaration = true,
				actions = file_actions,
			},
			definitions = {
				prompt = "📖 LSP 定义: ",
				file_icons = true,
				color_icons = true,
				jump1 = true,
				actions = file_actions,
			},
			document_symbols = {
				prompt = "🔠 LSP 符号: ",
				file_icons = true,
				color_icons = true,
				symbol_style = 1,
				child_prefix = true,
				actions = file_actions,
			},
			workspace_symbols = {
				prompt = "🏢 LSP 工作区符号: ",
				file_icons = true,
				color_icons = true,
				symbol_style = 1,
				actions = file_actions,
			},
			diagnostics = {
				document = {
					prompt = "⚠️ 文档诊断: ",
					file_icons = false,
					git_icons = false,
					color_headings = true,
					diag_icons = true,
					diag_source = true,
					diag_code = true,
					multiline = 2,
				},
				workspace = {
					prompt = "⚠️ 工作区诊断: ",
					file_icons = false,
					git_icons = false,
					color_headings = true,
					diag_icons = true,
					diag_source = true,
					diag_code = true,
					multiline = 2,
				},
			},
		},

		-- ==================== 高亮组 ====================
		highlights = {
			prompt = "🎨 高亮组: ",
		},

		-- ==================== 搜索历史 ====================
		search_history = {
			prompt = "🔎 搜索历史: ",
		},

		-- ==================== 跳转历史 ====================
		jumps = {
			prompt = "↕️ 跳转历史: ",
		},

		-- ==================== 命令历史 ====================
		command_history = {
			prompt = "📜 命令历史: ",
		},
	})
end)

-- ==================== 快捷键映射 ====================
local fzf_lua = require("fzf-lua")

local map = function(key, func, desc)
	vim.keymap.set("n", key, func, { desc = desc })
end

-- ############################ 文件与搜索 ############################

map("<leader>ff", function()
	fzf_lua.files()
end, "文件查找 (智能工具选择)")

map("<leader>fg", function()
	fzf_lua.live_grep()
end, "全局文本搜索 (项目内)")

map("<leader>fw", function()
	fzf_lua.lgrep_curbuf()
end, "当前缓冲区文本搜索")

map("<leader>fW", function()
	local filelist = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			local name = vim.api.nvim_buf_get_name(buf)
			if name ~= "" and vim.fn.filereadable(name) == 1 then
				table.insert(filelist, vim.fn.fnameescape(name))
			end
		end
	end
	if #filelist == 0 then
		vim.notify("没有已加载的缓冲区文件", vim.log.levels.WARN)
		return
	end
	fzf_lua.live_grep({
		prompt = "📚 所有缓冲区搜索: ",
		silent = true,
		cmd = "rg --column --line-number --no-heading --color=always --smart-case --max-columns=4096"
			.. " -- %s "
			.. table.concat(filelist, " "),
	})
end, "所有缓冲区文本搜索")

map("<leader>fb", function()
	fzf_lua.buffers()
end, "缓冲区管理")

map("<leader>fl", function()
	fzf_lua.lines()
end, "所有打开文件按行搜索")

map("<leader>fs", function()
	fzf_lua.lsp_document_symbols()
end, "当前文件符号")

map("<leader>fr", function()
	fzf_lua.oldfiles()
end, "最近文件")

map("<leader>f/", function()
	fzf_lua.search_history()
end, "搜索历史")

-- ############################ LSP功能 ############################

map("grr", function()
	fzf_lua.lsp_references()
end, "查找LSP引用")

map("gd", function()
	fzf_lua.lsp_definitions()
end, "查找LSP定义")

map("<leader>gs", function()
	fzf_lua.lsp_workspace_symbols()
end, "工作区符号")

-- ############################ 工具与辅助 ############################

map("<leader>fh", function()
	fzf_lua.helptags()
end, "帮助文档")

map("<leader>fk", function()
	fzf_lua.keymaps()
end, "键位映射")

map("<leader>fm", function()
	fzf_lua.marks()
end, "跳转标记")

map("<leader>fc", function()
	fzf_lua.command_history()
end, "命令历史")

map("<leader>f?", function()
	fzf_lua.builtin()
end, "fzf-lua 命令列表")

-- ############################ 快速补全 ############################

vim.keymap.set("i", "<C-x><C-f>", function()
	fzf_lua.complete_path()
end, { desc = "路径补全" })

vim.keymap.set("i", "<C-x><C-l>", function()
	fzf_lua.complete_bline()
end, { desc = "当前文件行补全" })

-- ############################ 其他功能 ############################

map("<leader>fq", function()
	local qf_list = vim.fn.getqflist()
	if #qf_list > 0 then
		vim.cmd("copen")
	else
		vim.notify("Quickfix 列表为空", vim.log.levels.INFO)
	end
end, "打开 Quickfix")

map("<leader>fR", function()
	fzf_lua.resume()
end, "恢复上次搜索")

map("<leader>fx", function()
	fzf_lua.builtin()
end, "全局选取器")

-- ############################ 工具状态 ############################

local function show_tools_status()
	local tools = {}
	local checks = {
		{ "fzf", "fzf" },
		{ "rg", "ripgrep" },
		{ "fd", "fd" },
		{ "bat", "bat" },
		{ "grep", "grep" },
		{ "find", "find" },
	}
	for _, item in ipairs(checks) do
		local cmd, name = item[1], item[2]
		table.insert(tools, name .. (vim.fn.executable(cmd) == 1 and " ✓" or " ✗"))
	end
	vim.notify("当前使用的工具:\n" .. table.concat(tools, "\n"), vim.log.levels.INFO)
end

map("<leader>ft", show_tools_status, "显示工具状态")

-- ############################ 帮助菜单 ############################

local function show_help()
	local help_lines = {
		"🌟 fzf-lua 快捷键说明",
		"",
		"📁 文件与搜索:",
		"  <leader>ff   - 文件查找 (智能工具选择)",
		"  <leader>fg   - 全局文本搜索 (项目内)",
		"  <leader>fw   - 当前缓冲区文本搜索",
		"  <leader>fW   - 所有缓冲区文本搜索",
		"  <leader>fb   - 缓冲区管理",
		"  <leader>fl   - 所有打开文件按行搜索",
		"  <leader>fs   - 当前文件符号",
		"  <leader>fr   - 最近文件",
		"  <leader>f/   - 搜索历史",
		"",
		"🏷️  LSP功能:",
		"  grr        - 查找LSP引用",
		"  gd         - 查找LSP定义",
		"  <leader>gs  - 工作区符号",
		"",
		"🛠️  工具与辅助:",
		"  <leader>fh   - 帮助文档",
		"  <leader>fk   - 键位映射",
		"  <leader>fm   - 跳转标记",
		"  <leader>fc   - 命令历史",
		"  <leader>f?   - fzf-lua命令列表",
		"  <leader>ft   - 显示工具状态",
		"",
		"⚡ 快速操作:",
		"  <leader>fq   - 打开Quickfix",
		"  <leader>fR   - 恢复上次搜索",
		"  <leader>fx   - 全局选取器",
		"",
		"🔧 在fzf窗口中:",
		"  Enter    - 打开/跳转",
		"  Ctrl-s   - 水平分屏",
		"  Ctrl-v   - 垂直分屏",
		"  Ctrl-t   - 新标签页",
		"  Alt-q    - 发送到Quickfix",
		"  Ctrl-g   - 切换搜索模式",
		"",
		"💡 智能工具检测:",
		"  文件搜索: fd > rg > find",
		"  文本搜索: rg > grep",
		"  预览: bat > cat",
	}
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = 70,
		height = #help_lines + 2,
		col = math.floor((vim.o.columns - 70) / 2),
		row = math.floor((vim.o.lines - #help_lines - 2) / 2),
		style = "minimal",
		border = "rounded",
	})
	vim.api.nvim_set_option_value("wrap", true, { win = win })
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	vim.keymap.set("n", "<ESC>", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })
end

map("<leader>?", show_help, "显示fzf-lua快捷键帮助")

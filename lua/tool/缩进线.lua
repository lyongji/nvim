-- lua/internal/indent.lua
-- 原生缩进指南模块
-- 功能：显示缩进线 + 高亮当前光标所在作用域
-- 空行继承上下文缩进，确保缩进线连续不中断

local api = vim.api
local M = {}

-- =============================================
-- 默认配置
-- =============================================
local config = {
	char = "┊",
	scope_char = "│",
	only_current = true,
	priority = 100,
	exclude_ft = {
		"help",
		"dashboard",
		"lazy",
		"mason",
		"notify",
		"NvimTree",
		"neo-tree",
		"Trouble",
	},
	exclude_bt = {
		"terminal",
		"nofile",
		"quickfix",
		"prompt",
	},
}

local ns_indent = api.nvim_create_namespace("indent_guide")
local ns_scope = api.nvim_create_namespace("indent_scope")

-- =============================================
-- 高亮组
-- =============================================

local function setup_highlights()
	api.nvim_set_hl(0, "IndentLine", {
		fg = "#3b3b3b",
		nocombine = true,
	})
	api.nvim_set_hl(0, "IndentLineScope", {
		fg = "#e0af68",
		bold = true,
		nocombine = true,
	})
end

-- =============================================
-- 工具函数
-- =============================================

local function is_excluded(bufnr)
	local ft = api.nvim_get_option_value("filetype", { buf = bufnr })
	local bt = api.nvim_get_option_value("buftype", { buf = bufnr })
	return vim.tbl_contains(config.exclude_ft, ft) or vim.tbl_contains(config.exclude_bt, bt)
end

--- 获取缓冲区的缩进步长
--- ✅ 优先使用 shiftwidth，为 0 时回退到 tabstop
---    最终保底为 2，防止步长为 0 导致死循环
---@param bufnr integer
---@return integer
local function get_sw(bufnr)
	local sw = api.nvim_get_option_value("shiftwidth", { buf = bufnr })
	if sw == 0 then
		sw = api.nvim_get_option_value("tabstop", { buf = bufnr })
	end
	-- ✅ 保底值，防止为 0
	return math.max(sw, 1)
end

--- 计算一行的缩进空格数（纯计算，不处理空行）
---@param bufnr integer
---@param line string
---@return integer
local function calc_indent(bufnr, line)
	local sw = get_sw(bufnr)
	local count = 0
	for i = 1, #line do
		local c = line:sub(i, i)
		if c == "\t" then
			count = count + (sw - (count % sw))
		elseif c == " " then
			count = count + 1
		else
			break
		end
	end
	return count
end

--- 判断是否为空行
---@param bufnr integer
---@param lnum integer 0-indexed
---@return boolean
local function is_empty_line(bufnr, lnum)
	local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
	return not line or line:match("^%s*$") ~= nil
end

--- 获取指定行的缩进级别
--- raw=true:  空行返回 -1（用于作用域边界检测）
--- raw=false: 空行继承上下文缩进（取上下最近非空行的较小值）
---@param bufnr integer
---@param lnum integer 0-indexed
---@param raw? boolean
---@return integer
local function get_indent(bufnr, lnum, raw)
	local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
	local is_empty = not line or line:match("^%s*$")

	if is_empty and raw then
		return -1
	end

	if not is_empty then
		return calc_indent(bufnr, line)
	end

	-- 空行继承上下文
	local total = api.nvim_buf_line_count(bufnr)
	local above, below = 0, 0

	for i = lnum - 1, 0, -1 do
		if not is_empty_line(bufnr, i) then
			local l = api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
			above = calc_indent(bufnr, l)
			break
		end
	end

	for i = lnum + 1, total - 1 do
		if not is_empty_line(bufnr, i) then
			local l = api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]
			below = calc_indent(bufnr, l)
			break
		end
	end

	return math.min(above, below)
end

--- ✅ 自动检测缓冲区实际使用的缩进步长
--- 扫描可视区域内的行，统计最常见的缩进差值
--- 解决 shiftwidth 与文件实际缩进不一致的问题
---
--- 例：文件用 2 空格缩进但 shiftwidth=4 时
---     不检测的话，缩进线只画在 4,8,12... 列
---     检测后，缩进线正确画在 2,4,6,8... 列
---@param bufnr integer
---@param win integer
---@return integer 检测到的缩进步长
local function detect_indent_step(bufnr, win)
	local top = vim.fn.line("w0", win) - 1
	local bot = vim.fn.line("w$", win)
	local counts = {} -- 统计各缩进差值出现的次数
	local prev_indent = 0

	for lnum = top, bot - 1 do
		local indent = get_indent(bufnr, lnum, true)
		if indent > 0 then
			local diff = math.abs(indent - prev_indent)
			-- 只统计合理的缩进差值（1~8）
			if diff > 0 and diff <= 8 then
				counts[diff] = (counts[diff] or 0) + 1
			end
			prev_indent = indent
		end
	end

	-- 找出出现次数最多的差值
	local best_step, best_count = get_sw(bufnr), 0
	for step, count in pairs(counts) do
		if count > best_count then
			best_step = step
			best_count = count
		end
	end

	return math.max(best_step, 1)
end

-- =============================================
-- 作用域检测
-- =============================================

---@param bufnr integer
---@param step integer 缩进步长
---@return integer scope_indent
---@return integer start_line 0-indexed
---@return integer end_line 0-indexed
local function find_scope(bufnr, step)
	local cursor_row = api.nvim_win_get_cursor(0)[1] - 1
	local total = api.nvim_buf_line_count(bufnr)

	-- 空行自动继承上下文缩进
	local cursor_indent = get_indent(bufnr, cursor_row)

	if cursor_indent <= 0 then
		return 0, 0, 0
	end

	-- ✅ 使用检测到的步长对齐
	local scope_indent = math.floor((cursor_indent - 1) / step) * step + step

	local start_line = cursor_row
	for i = cursor_row - 1, 0, -1 do
		local ind = get_indent(bufnr, i, true)
		if ind == -1 then
		-- 空行跳过
		elseif ind < scope_indent then
			break
		else
			start_line = i
		end
	end

	local end_line = cursor_row
	for i = cursor_row + 1, total - 1 do
		local ind = get_indent(bufnr, i, true)
		if ind == -1 then
		-- 空行跳过
		elseif ind < scope_indent then
			break
		else
			end_line = i
		end
	end

	return scope_indent, start_line, end_line
end

-- =============================================
-- 渲染
-- =============================================

--- 渲染普通缩进线
---@param bufnr integer
---@param win integer
---@param step integer 缩进步长
local function render_indent(bufnr, win, step)
	api.nvim_buf_clear_namespace(bufnr, ns_indent, 0, -1)

	local top = vim.fn.line("w0", win) - 1
	local bot = vim.fn.line("w$", win)

	for lnum = top, bot - 1 do
		local indent = get_indent(bufnr, lnum)
		if indent > 0 then
			-- ✅ 使用检测到的步长画线
			for col = step, indent - 1, step do
				if col > 0 then
					api.nvim_buf_set_extmark(bufnr, ns_indent, lnum, 0, {
						virt_text = { { config.char, "IndentLine" } },
						virt_text_pos = "overlay",
						virt_text_win_col = col,
						priority = config.priority,
						hl_mode = "combine",
					})
				end
			end
		end
	end
end

--- 渲染作用域高亮线
---@param bufnr integer
---@param step integer 缩进步长
local function render_scope(bufnr, step)
	api.nvim_buf_clear_namespace(bufnr, ns_scope, 0, -1)

	local scope_indent, start_line, end_line = find_scope(bufnr, step)
	if scope_indent <= 0 then
		return
	end

	-- ✅ 使用检测到的步长计算作用域线位置
	local col = scope_indent - step

	if col <= 0 then
		return
	end

	for lnum = start_line, end_line do
		api.nvim_buf_set_extmark(bufnr, ns_scope, lnum, 0, {
			virt_text = { { config.scope_char, "IndentLineScope" } },
			virt_text_pos = "overlay",
			virt_text_win_col = col,
			priority = config.priority + 1,
			hl_mode = "combine",
		})
	end
end

--- 完整刷新
local function refresh()
	local bufnr = api.nvim_get_current_buf()
	local win = api.nvim_get_current_win()

	if is_excluded(bufnr) then
		return
	end

	-- ✅ 自动检测缩进步长，解决 shiftwidth 不匹配问题
	local step = detect_indent_step(bufnr, win)

	render_indent(bufnr, win, step)
	render_scope(bufnr, step)
end

-- =============================================
-- 防抖
-- =============================================

local timer = vim.uv.new_timer()

local function debounced_refresh()
	timer:stop()
	timer:start(30, 0, vim.schedule_wrap(refresh))
end

-- =============================================
-- 公共接口
-- =============================================

--- 启动缩进指南
---@param opts? table
function M.setup(opts)
	if opts then
		config = vim.tbl_deep_extend("force", config, opts)
	end

	setup_highlights()

	local group = api.nvim_create_augroup("IndentGuide", { clear = true })

	api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group,
		callback = debounced_refresh,
	})

	api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		callback = debounced_refresh,
	})

	api.nvim_create_autocmd({ "BufEnter", "WinScrolled", "WinResized" }, {
		group = group,
		callback = debounced_refresh,
	})

	api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = setup_highlights,
	})

	refresh()
end

--- 禁用缩进指南
function M.disable()
	pcall(api.nvim_del_augroup_by_name, "IndentGuide")
	for _, bufnr in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_is_valid(bufnr) then
			api.nvim_buf_clear_namespace(bufnr, ns_indent, 0, -1)
			api.nvim_buf_clear_namespace(bufnr, ns_scope, 0, -1)
		end
	end
	timer:stop()
end

return M



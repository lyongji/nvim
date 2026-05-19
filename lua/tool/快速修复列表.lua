-- float_qf.lua
-- 浮动快速修复列表 & 位置列表
-- 接管原生 quickfix / loclist，支持右侧/底部布局切换
-- 依赖 float_win 模块

local api = vim.api
local fn = vim.fn
local new_float = require('tool.依赖.window').new_float

---@class FloatQF
---@field win FloatWin 浮动窗口实例
---@field items table[] 列表条目
---@field selected integer 当前选中行（1-indexed）
---@field list_type 'qf'|'loc' 列表类型
---@field target_win integer 触发窗口 ID（loclist 使用）
---@field ns integer 高亮命名空间
---@field ns_cursor integer 光标高亮命名空间
---@field au_group integer 自动命令组
local FloatQF = {}
FloatQF.__index = FloatQF

-- 单例存储：qf 和 loc 各自独立
local instances = { qf = nil, loc = nil }

-- ── 布局 ────────────────────────────────────────────────────────

-- 布局索引：0 = 右侧（默认），1 = 底部
local layout_index = 0

local LAYOUTS = {
  [0] = { width = 0.4, height = 0.8, row = 'c', col = 'r', anchor = 'NE', name = '右侧' },
  [1] = { width = 0.9, height = 0.35, row = 'b', col = 'c', anchor = 'SW', name = '底部' },
}

-- ── 配置 ────────────────────────────────────────────────────────

local CONFIG = {
  border = 'rounded',
  title_pos = 'center',
  filetype = 'floatqf',
  -- 文件名列占可用宽度的比例
  filename_ratio = 0.45,
  -- 图标
  icons = {
    error   = ' ',
    warning = ' ',
    info    = ' ',
    hint    = '󰌶 ',
    text    = '󰦨 ',
  },
  -- 高亮组
  hl = {
    selected  = 'CursorLine',
    filename  = 'Directory',
    lnum      = 'LineNr',
    error     = 'DiagnosticError',
    warning   = 'DiagnosticWarn',
    info      = 'DiagnosticInfo',
    hint      = 'DiagnosticHint',
    text_hl   = 'Normal',
    border    = 'FloatBorder',
    header    = 'Title',
    empty     = 'Comment',
    separator = 'Comment',
  },
}

-- ── 辅助函数 ─────────────────────────────────────────────────────

--- 计算字符串的实际显示宽度（正确处理中文、图标等多字节字符）
---@param str string
---@return integer
local function display_width(str)
  return fn.strdisplaywidth(str)
end

--- 按显示宽度截断字符串，超出部分用 … 替代
---@param str string 原始字符串
---@param max integer 最大显示宽度
---@return string 截断后的字符串
local function truncate_display(str, max)
  if max <= 0 then return '' end
  if display_width(str) <= max then return str end
  local result = ''
  local chars = fn.split(str, '\\zs')
  for _, ch in ipairs(chars) do
    if display_width(result .. ch) > max - 1 then
      return result .. '…'
    end
    result = result .. ch
  end
  return result
end

--- 按显示宽度右填充空格，使所有行的分隔符对齐
---@param str string 原始字符串
---@param target_width integer 目标显示宽度
---@return string 填充后的字符串
local function pad_right(str, target_width)
  local w = display_width(str)
  return w >= target_width and str or str .. string.rep(' ', target_width - w)
end

--- 解析条目严重级别，返回类别名、图标、高亮组
---@param type_char string 单字符类型标识（E/W/I/N）
---@return string category 类别名
---@return string icon 图标
---@return string hl_group 高亮组
local function parse_type(type_char)
  local map = {
    E = { 'error',   CONFIG.icons.error,   CONFIG.hl.error },
    W = { 'warning', CONFIG.icons.warning, CONFIG.hl.warning },
    I = { 'info',    CONFIG.icons.info,    CONFIG.hl.info },
    N = { 'hint',    CONFIG.icons.hint,    CONFIG.hl.hint },
  }
  local entry = map[(type_char or ''):upper()] or { 'text', CONFIG.icons.text, CONFIG.hl.text_hl }
  return entry[1], entry[2], entry[3]
end

--- 将绝对路径转为相对路径（兼容 Windows 反斜杠）
---@param abs_path string 绝对路径
---@return string 相对路径
local function relative_path(abs_path)
  local cwd = fn.getcwd():gsub('\\', '/') .. '/'
  local path = abs_path:gsub('\\', '/')
  if path:sub(1, #cwd) == cwd then
    return path:sub(#cwd + 1)
  end
  return fn.fnamemodify(abs_path, ':~:.')
end

--- 关闭所有原生 quickfix / loclist 窗口
--- 注意：loclist 的 buftype 也是 'quickfix'，通过 getwininfo 的 loclist 字段区分
---@param list_type 'qf'|'loc'|'all' 要关闭的类型
local function close_native_windows(list_type)
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local buf = api.nvim_win_get_buf(win)
      local bt = api.nvim_get_option_value('buftype', { buf = buf })
      if bt == 'quickfix' then
        local info = fn.getwininfo(win)
        if info and #info > 0 then
          local is_loc = info[1].loclist == 1
          if list_type == 'all'
            or (list_type == 'qf' and not is_loc)
            or (list_type == 'loc' and is_loc) then
            pcall(api.nvim_win_close, win, true)
          end
        end
      end
    end
  end
end

--- 获取当前窗口 ID（排除浮动窗口）
--- 用于 loclist 需要关联到具体的编辑窗口
---@return integer 有效的非浮动窗口 ID
local function get_normal_win()
  local cur = api.nvim_get_current_win()
  local conf = api.nvim_win_get_config(cur)
  if conf.relative == '' then return cur end
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_config(w).relative == '' then
      return w
    end
  end
  return cur
end

-- ── 格式化 ───────────────────────────────────────────────────────

--- 格式化单条条目为显示行，并生成高亮标记
---@param item table quickfix/loclist 条目
---@param fname_col_width integer 文件名列的显示宽度
---@param desc_col_width integer 描述列的显示宽度
---@return string line 格式化后的文本
---@return table[] marks 高亮标记 { byte_start, byte_end, hl_group }
local function format_item(item, fname_col_width, desc_col_width)
  local _, icon, type_hl = parse_type(item.type or '')

  -- 文件名
  local fname = ''
  if item.bufnr and item.bufnr > 0 then
    local bufname = api.nvim_buf_get_name(item.bufnr)
    fname = bufname ~= '' and relative_path(bufname) or '[未命名]'
  end

  -- 行号:列号
  local location = ''
  if item.lnum and item.lnum > 0 then
    location = string.format(':%d', item.lnum)
    if item.col and item.col > 0 then
      location = location .. string.format(':%d', item.col)
    end
  end

  -- 描述文本（去除首尾空白）
  local desc = (item.text or ''):match('^%s*(.-)%s*$')

  -- 组装各列
  local icon_part = icon
  local file_padded = pad_right(
    truncate_display(fname .. location, fname_col_width),
    fname_col_width
  )
  local sep = ' │ '
  local desc_truncated = truncate_display(desc, desc_col_width)
  local line = icon_part .. file_padded .. sep .. desc_truncated

  -- 构建高亮标记（基于字节偏移）
  local marks = {}
  local off = 0

  local ib = #icon_part
  table.insert(marks, { off, off + ib, type_hl })
  off = off + ib

  local fb = #file_padded
  table.insert(marks, { off, off + fb, CONFIG.hl.filename })
  off = off + fb

  local sb = #sep
  table.insert(marks, { off, off + sb, CONFIG.hl.separator })
  off = off + sb

  table.insert(marks, { off, off + #desc_truncated, type_hl })

  return line, marks
end

--- 生成统计摘要行（显示在列表顶部）
---@param items table[] 条目列表
---@return string 摘要文本
local function make_summary(items)
  local counts = { E = 0, W = 0, I = 0, N = 0, other = 0 }
  for _, item in ipairs(items) do
    local t = (item.type or ''):upper()
    if counts[t] then
      counts[t] = counts[t] + 1
    else
      counts.other = counts.other + 1
    end
  end

  local parts = {}
  if counts.E > 0 then table.insert(parts, CONFIG.icons.error .. counts.E) end
  if counts.W > 0 then table.insert(parts, CONFIG.icons.warning .. counts.W) end
  if counts.I > 0 then table.insert(parts, CONFIG.icons.info .. counts.I) end
  if counts.N > 0 then table.insert(parts, CONFIG.icons.hint .. counts.N) end
  if counts.other > 0 then table.insert(parts, CONFIG.icons.text .. counts.other) end

  return string.format(
    ' 共 %d 项  %s    L:布局',
    #items,
    table.concat(parts, '  ')
  )
end

-- ── FloatQF 方法 ─────────────────────────────────────────────────

--- 渲染缓冲区内容和高亮
function FloatQF:render()
  if not self.win:valid() then return end

  local bufnr = self.win.bufnr
  local win_width = api.nvim_win_get_width(self.win.winid)
  local content_width = win_width - 2

  api.nvim_buf_clear_namespace(bufnr, self.ns, 0, -1)

  local type_name = self.list_type == 'loc' and '位置列表' or '快速修复'

  -- 空列表提示
  if #self.items == 0 then
    api.nvim_set_option_value('modifiable', true, { buf = bufnr })
    self.win:set_lines({
      '',
      '   暂无' .. type_name .. '条目',
      '',
      '   按 q 或 <Esc> 关闭',
      '   按 L 切换布局（右侧/底部）',
      '',
    })
    api.nvim_set_option_value('modifiable', false, { buf = bufnr })
    for i = 0, 5 do
      api.nvim_buf_add_highlight(bufnr, self.ns, CONFIG.hl.empty, i, 0, -1)
    end
    return
  end

  -- 计算列宽
  local icon_width = 2
  local sep_width = 3
  local available = content_width - icon_width - sep_width
  local fname_col_width = math.floor(available * CONFIG.filename_ratio)
  local desc_col_width = available - fname_col_width

  local lines = {}
  local all_marks = {}

  -- 摘要行
  local summary = make_summary(self.items)
  table.insert(lines, summary)
  table.insert(all_marks, { { 0, #summary, CONFIG.hl.header } })

  -- 分隔线
  local sep_line = string.rep('─', content_width)
  table.insert(lines, sep_line)
  table.insert(all_marks, { { 0, #sep_line, CONFIG.hl.separator } })

  -- 条目行
  for _, item in ipairs(self.items) do
    local line, marks = format_item(item, fname_col_width, desc_col_width)
    table.insert(lines, line)
    table.insert(all_marks, marks)
  end

  -- 帮助行
  table.insert(lines, '')
  table.insert(all_marks, {})

  local help1 = truncate_display(
    ' j/k:移动  Enter:跳转  s:分屏  v:竖屏  p:预览',
    content_width
  )
  local help2 = truncate_display(
    ' dd:删除项  C:清空  L:布局  R:刷新  q:关闭',
    content_width
  )
  table.insert(lines, help1)
  table.insert(all_marks, { { 0, #help1, CONFIG.hl.empty } })
  table.insert(lines, help2)
  table.insert(all_marks, { { 0, #help2, CONFIG.hl.empty } })

  -- 写入缓冲区
  api.nvim_set_option_value('modifiable', true, { buf = bufnr })
  self.win:set_lines(lines)
  api.nvim_set_option_value('modifiable', false, { buf = bufnr })

  -- 应用高亮
  for row, marks in ipairs(all_marks) do
    for _, mark in ipairs(marks) do
      api.nvim_buf_add_highlight(bufnr, self.ns, mark[3], row - 1, mark[1], mark[2])
    end
  end

  self:highlight_selected()
end

--- 更新选中行高亮
function FloatQF:highlight_selected()
  if not self.win:valid() or #self.items == 0 then return end

  local bufnr = self.win.bufnr
  api.nvim_buf_clear_namespace(bufnr, self.ns_cursor, 0, -1)

  -- +2 因为有摘要行(第0行)和分隔线(第1行)
  local buf_line = self.selected + 1
  if buf_line >= api.nvim_buf_line_count(bufnr) then return end

  api.nvim_buf_set_extmark(bufnr, self.ns_cursor, buf_line, 0, {
    end_row = buf_line + 1,
    hl_group = CONFIG.hl.selected,
    hl_eol = true,
  })

  pcall(api.nvim_win_set_cursor, self.win.winid, { buf_line + 1, 0 })
end

--- 移动选中项（支持循环）
---@param delta integer 移动量
function FloatQF:move(delta)
  if #self.items == 0 then return end
  self.selected = ((self.selected - 1 + delta) % #self.items) + 1
  self:highlight_selected()
end

--- 找到合适的目标窗口（非浮动窗口）
---@param item table 条目
---@return integer|nil win_id
function FloatQF:find_target_win(item)
  -- 1. 优先使用关联窗口
  if self.target_win
    and self.target_win > 0
    and api.nvim_win_is_valid(self.target_win)
    and api.nvim_win_get_config(self.target_win).relative == '' then
    return self.target_win
  end
  -- 2. 已显示该 buffer 的普通窗口
  if item.bufnr and item.bufnr > 0 then
    for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
      if api.nvim_win_get_config(w).relative == ''
        and api.nvim_win_get_buf(w) == item.bufnr then
        return w
      end
    end
  end
  -- 3. 任意普通窗口
  for _, w in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_config(w).relative == '' then
      return w
    end
  end
  return nil
end

--- 在目标窗口设置光标并居中
---@param win integer
---@param item table
local function set_cursor_to_item(win, item)
  if item.lnum and item.lnum > 0 then
    local col = (item.col and item.col > 0) and (item.col - 1) or 0
    pcall(api.nvim_win_set_cursor, win, { item.lnum, col })
    api.nvim_win_call(win, function() vim.cmd('normal! zz') end)
  end
end

--- 跳转到选中条目并关闭
function FloatQF:jump()
  if #self.items == 0 then return end
  local item = self.items[self.selected]
  self:close()

  if not (item.bufnr and item.bufnr > 0 and api.nvim_buf_is_valid(item.bufnr)) then
    vim.notify('无效的缓冲区', vim.log.levels.WARN)
    return
  end

  local win = self:find_target_win(item)
  if not win then
    vim.notify('找不到可用的窗口', vim.log.levels.WARN)
    return
  end

  api.nvim_set_current_win(win)
  api.nvim_win_set_buf(win, item.bufnr)
  set_cursor_to_item(win, item)
end

--- 水平分屏打开
function FloatQF:jump_in_split()
  if #self.items == 0 then return end
  local item = self.items[self.selected]
  self:close()

  if not (item.bufnr and item.bufnr > 0 and api.nvim_buf_is_valid(item.bufnr)) then
    vim.notify('无效的缓冲区', vim.log.levels.WARN)
    return
  end

  local base_win = self:find_target_win(item)
  if base_win then api.nvim_set_current_win(base_win) end
  vim.cmd('split')
  api.nvim_win_set_buf(0, item.bufnr)
  set_cursor_to_item(0, item)
end

--- 垂直分屏打开
function FloatQF:jump_in_vsplit()
  if #self.items == 0 then return end
  local item = self.items[self.selected]
  self:close()

  if not (item.bufnr and item.bufnr > 0 and api.nvim_buf_is_valid(item.bufnr)) then
    vim.notify('无效的缓冲区', vim.log.levels.WARN)
    return
  end

  local base_win = self:find_target_win(item)
  if base_win then api.nvim_set_current_win(base_win) end
  vim.cmd('vsplit')
  api.nvim_win_set_buf(0, item.bufnr)
  set_cursor_to_item(0, item)
end

--- 预览当前选中项（不关闭浮动窗口）
function FloatQF:preview()
  if #self.items == 0 then return end
  local item = self.items[self.selected]
  if not (item.bufnr and item.bufnr > 0 and api.nvim_buf_is_valid(item.bufnr)) then return end
  if not (item.lnum and item.lnum > 0) then return end

  local win = self:find_target_win(item)
  if not win then return end

  -- 临时禁用自动关闭，防止切换 buffer 时触发 BufLeave 关闭浮动窗口
  local saved_au = self.au_group
  self.au_group = nil

  api.nvim_win_set_buf(win, item.bufnr)

  -- 安全设置光标：确保行号不超出 buffer 实际行数
  local line_count = api.nvim_buf_line_count(item.bufnr)
  local lnum = math.min(item.lnum, line_count)
  local col = (item.col and item.col > 0) and (item.col - 1) or 0
  pcall(api.nvim_win_set_cursor, win, { lnum, col })
  pcall(api.nvim_win_call, win, function() vim.cmd('normal! zz') end)

  -- 确保焦点回到浮动窗口
  if self.win and self.win:valid() then
    api.nvim_set_current_win(self.win.winid)
  end

  -- 恢复自动命令组
  self.au_group = saved_au
end

--- 删除当前选中的条目
function FloatQF:remove_item()
  if #self.items == 0 then return end

  -- 从列表中移除
  table.remove(self.items, self.selected)

  -- 写回列表
  if self.list_type == 'qf' then
    fn.setqflist(self.items, 'r')
  else
    fn.setloclist(self.target_win, self.items, 'r')
  end

  -- 调整选中位置
  if #self.items == 0 then
    self.selected = 1
  elseif self.selected > #self.items then
    self.selected = #self.items
  end

  self:render()

  if #self.items == 0 then
    vim.notify('列表已清空', vim.log.levels.INFO)
  end
end

--- 清空整个列表
function FloatQF:clear_list()
  if self.list_type == 'qf' then
    fn.setqflist({}, 'r')
  else
    fn.setloclist(self.target_win, {}, 'r')
  end

  self.items = {}
  self.selected = 1
  self:render()

  local type_name = self.list_type == 'loc' and '位置列表' or '快速修复列表'
  vim.notify(type_name .. '已清空', vim.log.levels.INFO)
end

--- 切换布局
function FloatQF:switch_layout()
  local sel = self.selected
  local items = self.items
  local ltype = self.list_type
  local twin = self.target_win
  self:close()
  layout_index = 1 - layout_index
  local instance = open_float_list(ltype, twin)
  if instance then
    instance.items = items
    instance.selected = math.min(sel, math.max(#items, 1))
    instance:render()
  end
end

--- 设置键映射
function FloatQF:setup_keymaps()
  local bufnr = self.win.bufnr

  local function map(key, fn_cb, desc)
    vim.keymap.set('n', key, fn_cb, {
      noremap = true, silent = true, buffer = bufnr, desc = desc,
    })
  end

  -- 导航
  map('j',       function() self:move(1) end,                                  '下移一项')
  map('k',       function() self:move(-1) end,                                 '上移一项')
  map('<Down>',  function() self:move(1) end,                                  '下移一项')
  map('<Up>',    function() self:move(-1) end,                                 '上移一项')
  map('<C-d>',   function() self:move(10) end,                                 '向下翻页')
  map('<C-u>',   function() self:move(-10) end,                                '向上翻页')
  map('gg',      function() self:move(-self.selected + 1) end,                 '跳到首项')
  map('G',       function()
    self.selected = #self.items; self:highlight_selected()
  end,                                                                         '跳到末项')

  -- 打开
  map('<CR>',    function() self:jump() end,                                   '跳转并关闭')
  map('o',       function() self:jump() end,                                   '跳转并关闭')
  map('s',       function() self:jump_in_split() end,                          '水平分屏打开')
  map('v',       function() self:jump_in_vsplit() end,                         '垂直分屏打开')

  -- 预览
  map('p',       function() self:preview() end,                                '预览条目')
  map('<Tab>',   function()  self:move(1); self:preview()end,                  '预览并下移')
  map('<S-Tab>', function()  self:move(-1); self:preview()end,                 '预览并上移')

  -- 编辑列表
  map('dd',      function() self:remove_item() end,                            '删除当前条目')
  map('C',       function() self:clear_list() end,                             '清空整个列表')

  -- 其他
  map('L',       function() self:switch_layout() end,                          '切换布局')
  map('q',       function() self:close() end,                                  '关闭窗口')
  map('<Esc>',   function() self:close() end,                                  '关闭窗口')
  map('R',       function() self:refresh() end,                                '刷新列表')
end

--- 刷新列表数据
function FloatQF:refresh()
  if self.list_type == 'qf' then
    self.items = fn.getqflist()
  else
    local win = self.target_win
    if not win or win <= 0 or not api.nvim_win_is_valid(win) then
      win = get_normal_win()
      self.target_win = win
    end
    self.items = fn.getloclist(win)
  end
  self.selected = math.min(self.selected, math.max(#self.items, 1))
  self:render()
end

--- 关闭浮动窗口并清理资源
function FloatQF:close()
  if self.au_group then
    pcall(api.nvim_del_augroup_by_id, self.au_group)
    self.au_group = nil
  end
  if self.win then
    self.win:close()
  end
  instances[self.list_type] = nil
end

--- 设置自动命令
function FloatQF:setup_autocmds()
  local ltype = self.list_type
  self.au_group = api.nvim_create_augroup('FloatList_' .. ltype, { clear = true })

  -- 离开缓冲区时自动关闭
  api.nvim_create_autocmd('BufLeave', {
    group = self.au_group,
    buffer = self.win.bufnr,
    callback = function()
      vim.defer_fn(function()
        if instances[ltype] then
          instances[ltype]:close()
        end
      end, 50)
    end,
    desc = '离开缓冲区时关闭浮动列表',
  })

  -- qf 类型监听列表变更
  if ltype == 'qf' then
    api.nvim_create_autocmd('QuickFixCmdPost', {
      group = self.au_group,
      pattern = '[^l]*',
      callback = function()
        if self.win and self.win:valid() then self:refresh() end
      end,
      desc = '快速修复列表变更时自动刷新',
    })
  end

  -- 窗口大小变化时重建（保持当前布局）
  api.nvim_create_autocmd('VimResized', {
    group = self.au_group,
    callback = function()
      if self.win and self.win:valid() then
        local sel = self.selected
        local items = self.items
        local twin = self.target_win
        self:close()
        local instance = open_float_list(ltype, twin)
        if instance then
          instance.items = items
          instance.selected = math.min(sel, #instance.items)
          instance:render()
        end
      end
    end,
    desc = '终端大小变化时重建浮动窗口',
  })
end

-- ── 核心工厂函数 ─────────────────────────────────────────────────

--- 打开浮动列表窗口
---@param list_type 'qf'|'loc' 列表类型
---@param from_win? integer 触发窗口 ID（loclist 需要）
---@return FloatQF|nil 浮动列表实例
function open_float_list(list_type, from_win)
  -- 已存在且有效 → 刷新
  if instances[list_type]
    and instances[list_type].win
    and instances[list_type].win:valid() then
    instances[list_type]:refresh()
    return instances[list_type]
  end

  close_native_windows(list_type)

  local self = setmetatable({}, FloatQF)
  self.list_type = list_type
  self.ns = api.nvim_create_namespace('floatlist_hl_' .. list_type)
  self.ns_cursor = api.nvim_create_namespace('floatlist_cursor_' .. list_type)

  -- 确定关联窗口
  if list_type == 'loc' then
    self.target_win = (from_win and from_win > 0 and api.nvim_win_is_valid(from_win))
      and from_win or get_normal_win()
  else
    self.target_win = 0
  end

  -- 获取列表数据和上次选中位置
  if list_type == 'qf' then
    self.items = fn.getqflist()
    local info = fn.getqflist({ idx = 0 })
    self.selected = (info.idx and info.idx > 0 and info.idx <= #self.items)
      and info.idx or 1
  else
    self.items = fn.getloclist(self.target_win)
    local info = fn.getloclist(self.target_win, { idx = 0 })
    self.selected = (info.idx and info.idx > 0 and info.idx <= #self.items)
      and info.idx or 1
  end

  -- 生成标题
  local type_name = list_type == 'qf' and '快速修复' or '位置列表'
  local layout = LAYOUTS[layout_index]
  local title = string.format(' 󰁨 %s │ %s ', type_name, layout.name)

  -- 创建浮动窗口
  self.win = new_float({
    width = layout.width,
    height = layout.height,
    row = layout.row,
    col = layout.col,
    anchor = layout.anchor,
    border = CONFIG.border,
    title = title,
    title_pos = CONFIG.title_pos,
    zindex = 60,
  }, true, true)

  -- 缓冲区设置
  self.win:bufopt({
    filetype = CONFIG.filetype,
    bufhidden = 'wipe',
    buftype = 'nofile',
    swapfile = false,
    modifiable = false,
  })

  -- 窗口设置
  self.win:winopt({
    number = false,
    relativenumber = false,
    signcolumn = 'no',
    cursorline = false,
    wrap = false,
    spell = false,
    list = false,
    winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel',
  })

  self:render()
  self:setup_keymaps()
  self:setup_autocmds()

  instances[list_type] = self
  return self
end

-- ── 公共接口 ─────────────────────────────────────────────────────

--- 切换列表
---@param list_type? 'qf'|'loc'
local function toggle(list_type)
  list_type = list_type or 'qf'

  if instances[list_type]
    and instances[list_type].win
    and instances[list_type].win:valid() then
    instances[list_type]:close()
    return nil
  end

  local from_win = (list_type == 'loc') and get_normal_win() or 0

  if list_type == 'loc' then
    local items = fn.getloclist(from_win)
    if #items == 0 then
      vim.notify('当前窗口没有位置列表', vim.log.levels.WARN)
      return nil
    end
  end

  return open_float_list(list_type, from_win)
end

--- 仅打开（已打开则刷新）
---@param list_type? 'qf'|'loc'
local function open(list_type)
  list_type = list_type or 'qf'
  local from_win = (list_type == 'loc') and get_normal_win() or 0
  return open_float_list(list_type, from_win)
end

--- 仅关闭
---@param list_type? 'qf'|'loc'
local function close(list_type)
  list_type = list_type or 'qf'
  if instances[list_type] then
    instances[list_type]:close()
  end
end

--- 导航到上/下一项（不打开浮动窗口）
---@param list_type 'qf'|'loc'
---@param direction 'prev'|'next'
local function navigate(list_type, direction)
  local cmd_map = {
    qf  = { prev = 'cprev', next = 'cnext', first = 'cfirst', last = 'clast' },
    loc = { prev = 'lprev', next = 'lnext', first = 'lfirst', last = 'llast' },
  }
  local cmds = cmd_map[list_type]
  local ok, err = pcall(vim.cmd, cmds[direction])
  if not ok then
    local msg = tostring(err)
    if msg:match('E553') then
      -- 到末尾了循环到头，到头了循环到末尾
      local wrap = direction == 'next' and 'first' or 'last'
      local ok2, err2 = pcall(vim.cmd, cmds[wrap])
      if not ok2 then
        vim.notify(tostring(err2), vim.log.levels.WARN)
      end
    elseif msg:match('E42') or msg:match('E776') then
      vim.notify('列表为空', vim.log.levels.INFO)
    else
      vim.notify(msg, vim.log.levels.WARN)
    end
  end
end

--- LSP 诊断转 quickfix 列表
---@param scope 'buffer'|'all'
local function diagnostics_to_qf(scope)
  local diagnostics = (scope == 'all')
    and vim.diagnostic.get()
    or vim.diagnostic.get(0)

  if #diagnostics == 0 then
    local name = (scope == 'all') and '工作区' or '当前文件'
    vim.notify(name .. '没有 LSP 诊断信息', vim.log.levels.INFO)
    return
  end

  local severity_map = {
    [vim.diagnostic.severity.ERROR] = 'E',
    [vim.diagnostic.severity.WARN]  = 'W',
    [vim.diagnostic.severity.INFO]  = 'I',
    [vim.diagnostic.severity.HINT]  = 'N',
  }

  local qf_list = {}
  for _, d in ipairs(diagnostics) do
    table.insert(qf_list, {
      bufnr = d.bufnr,
      lnum  = d.lnum + 1,
      col   = d.col + 1,
      text  = d.message,
      type  = severity_map[d.severity] or 'E',
    })
  end

  fn.setqflist(qf_list, 'r')
  open_float_list('qf', 0)
end

--- 手动添加条目到列表
--- 示例：add_item('qf', { filename = 'test.lua', lnum = 10, text = '待办事项' })
---@param list_type 'qf'|'loc'
---@param item table { bufnr?, filename?, lnum?, col?, text?, type? }
local function add_item(list_type, item)
  -- 如果传了 filename 但没传 bufnr，自动转换
  if item.filename and not item.bufnr then
    local buf = fn.bufnr(item.filename, true) -- true = 不存在则创建
    if buf > 0 then
      item.bufnr = buf
    end
  end

  if list_type == 'qf' then
    fn.setqflist({}, 'a', { items = { item } })
  else
    local win = get_normal_win()
    fn.setloclist(win, {}, 'a', { items = { item } })
  end

  -- 如果浮动窗口已打开，自动刷新
  if instances[list_type] and instances[list_type].win and instances[list_type].win:valid() then
    instances[list_type]:refresh()
  end
end

--- 添加当前光标位置到列表
---@param list_type 'qf'|'loc'
---@param text? string 备注文本，默认为当前行内容
local function add_current_pos(list_type, text)
  local pos = api.nvim_win_get_cursor(0)
  local buf = api.nvim_get_current_buf()
  -- 默认使用当前行内容作为描述
  if not text or text == '' then
    local lines = api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)
    text = (lines[1] or ''):match('^%s*(.-)%s*$')
  end

  add_item(list_type, {
    bufnr = buf,
    lnum  = pos[1],
    col   = pos[2] + 1,
    text  = text,
    type  = 'I', -- 标记为 Info 类型
  })

  local type_name = list_type == 'qf' and '快速修复' or '位置列表'
  vim.notify(
    string.format('已添加到%s: 第 %d 行', type_name, pos[1]),
    vim.log.levels.INFO
  )
end

--- 清空列表
---@param list_type 'qf'|'loc'
local function clear(list_type)
  list_type = list_type or 'qf'
  if list_type == 'qf' then
    fn.setqflist({}, 'r')
  else
    local win = get_normal_win()
    fn.setloclist(win, {}, 'r')
  end

  -- 如果浮动窗口已打开，刷新显示
  if instances[list_type] and instances[list_type].win and instances[list_type].win:valid() then
    instances[list_type]:refresh()
  end

  local type_name = list_type == 'qf' and '快速修复列表' or '位置列表'
  vim.notify(type_name .. '已清空', vim.log.levels.INFO)
end

-- ── 接管原生 quickfix / loclist ──────────────────────────────────

local hijack_group = api.nvim_create_augroup('FloatQF_Hijack', { clear = true })

-- 拦截原生窗口打开
api.nvim_create_autocmd('BufWinEnter', {
  group = hijack_group,
  callback = function(ev)
    local bt = api.nvim_get_option_value('buftype', { buf = ev.buf })
    if bt ~= 'quickfix' then return end

    vim.schedule(function()
      local cur_win = fn.bufwinid(ev.buf)
      if cur_win < 0 then return end

      local info = fn.getwininfo(cur_win)
      if not info or #info == 0 then return end

      local is_loc = info[1].loclist == 1

      if is_loc then
        close_native_windows('loc')
        open_float_list('loc', get_normal_win())
      else
        close_native_windows('qf')
        open_float_list('qf', 0)
      end
    end)
  end,
  desc = '拦截原生 quickfix/loclist 窗口',
})

-- 拦截 quickfix 命令
api.nvim_create_autocmd('QuickFixCmdPost', {
  group = hijack_group,
  pattern = '[^l]*',
  callback = function()
    vim.schedule(function()
      close_native_windows('qf')
      open_float_list('qf', 0)
    end)
  end,
  desc = '快速修复命令后自动打开浮动窗口',
})

-- 拦截 loclist 命令
api.nvim_create_autocmd('QuickFixCmdPost', {
  group = hijack_group,
  pattern = 'l*',
  callback = function()
    vim.schedule(function()
      local win = get_normal_win()
      close_native_windows('loc')
      open_float_list('loc', win)
    end)
  end,
  desc = '位置列表命令后自动打开浮动窗口',
})

-- ── 用户命令 ─────────────────────────────────────────────────────

api.nvim_create_user_command('FloatQF', function()
  toggle('qf')
end, { desc = '切换浮动快速修复列表' })

api.nvim_create_user_command('FloatLoc', function()
  toggle('loc')
end, { desc = '切换浮动位置列表' })

api.nvim_create_user_command('FloatQFPos', function()
  if instances.qf then instances.qf:switch_layout()
  elseif instances.loc then instances.loc:switch_layout() end
end, { desc = '切换列表布局' })

api.nvim_create_user_command('FloatQFClose', function()
  close('qf')
  close('loc')
end, { desc = '关闭所有浮动列表' })

-- :FloatQFAdd [text]  — 添加当前光标位置到快速修复列表
api.nvim_create_user_command('FloatQFAdd', function(opts)
  add_current_pos('qf', opts.args)
end, { desc = '添加当前位置到快速修复列表', nargs = '?' })

-- :FloatLocAdd [text]  — 添加当前光标位置到位置列表
api.nvim_create_user_command('FloatLocAdd', function(opts)
  add_current_pos('loc', opts.args)
end, { desc = '添加当前位置到位置列表', nargs = '?' })

-- :FloatQFClear / :FloatLocClear  — 清空列表
api.nvim_create_user_command('FloatQFClear', function()
  clear('qf')
end, { desc = '清空快速修复列表' })

api.nvim_create_user_command('FloatLocClear', function()
  clear('loc')
end, { desc = '清空位置列表' })

-- :FloatDiag [buffer|all]  — LSP 诊断转快速修复
api.nvim_create_user_command('FloatDiag', function(opts)
  diagnostics_to_qf(opts.args == 'all' and 'all' or 'buffer')
end, {
  desc = 'LSP 诊断转快速修复列表',
  nargs = '?',
  complete = function() return { 'buffer', 'all' } end,
})

-- 覆盖原生命令缩写
vim.cmd([[
  cnoreabbrev <expr> copen   getcmdtype()==':'&&getcmdline()=='copen'   ? 'FloatQF'      : 'copen'
  cnoreabbrev <expr> cclose  getcmdtype()==':'&&getcmdline()=='cclose'  ? 'FloatQFClose' : 'cclose'
  cnoreabbrev <expr> cwindow getcmdtype()==':'&&getcmdline()=='cwindow' ? 'FloatQF'      : 'cwindow'
  cnoreabbrev <expr> lopen   getcmdtype()==':'&&getcmdline()=='lopen'   ? 'FloatLoc'     : 'lopen'
  cnoreabbrev <expr> lclose  getcmdtype()==':'&&getcmdline()=='lclose'  ? 'FloatQFClose' : 'lclose'
  cnoreabbrev <expr> lwindow getcmdtype()==':'&&getcmdline()=='lwindow' ? 'FloatLoc'     : 'lwindow'
]])

-- ── 导出 ─────────────────────────────────────────────────────────

return {
  -- 快速修复列表
  toggle_qf  = function() return toggle('qf') end,
  open_qf    = function() return open('qf') end,
  close_qf   = function() close('qf') end,
  clear_qf   = function() clear('qf') end,

  -- 位置列表
  toggle_loc = function() return toggle('loc') end,
  open_loc   = function() return open('loc') end,
  close_loc  = function() close('loc') end,
  clear_loc  = function() clear('loc') end,

  -- 导航
  navigate   = navigate,

  -- 编辑列表
  add_item   = add_item,
  add_pos_qf = function(text) add_current_pos('qf', text) end,
  add_pos_loc = function(text) add_current_pos('loc', text) end,

  -- LSP 诊断
  diag_qf    = diagnostics_to_qf,

  -- 布局
  switch_layout = function()
    if instances.qf then instances.qf:switch_layout()
    elseif instances.loc then instances.loc:switch_layout() end
  end,
}

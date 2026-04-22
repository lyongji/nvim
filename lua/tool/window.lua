-- Neovim 浮动窗口工具模块
-- 提供便捷的浮动窗口创建、配置、管理功能
-- 支持比例尺寸、九宫格快捷定位、链式调用

local api = vim.api

-- 默认窗口配置
local DEFAULT_CONFIG = {
  style = 'minimal', -- 无行号、无状态栏等装饰
  border = 'rounded', -- 圆角边框
  noautocmd = false, -- 不禁止自动命令
}

--- 根据宽高的正负号计算窗口锚点方向
--- 正数：向下/向右展开  负数：向上/向左展开
--- 锚点示意：
---   NW──┐  ┌──NE
---       │  │
---   SW──┘  └──SE
---@param opts table 包含 width 和 height 的配置表
---@return string 锚点字符串，如 'NW', 'NE', 'SW', 'SE'
local function make_floating_popup_anchor(opts)
  local v = opts.height >= 0 and 'N' or 'S'
  local h = opts.width >= 0 and 'W' or 'E'
  return v .. h
end

--- 计算浮动窗口的实际尺寸
--- 支持两种模式：
---   - 绝对值模式：width/height >= 1 时直接作为字符数使用
---   - 比例模式：width/height < 1 时按屏幕比例计算（如 0.8 = 80%）
---@param opts table 包含 width 和 height 的配置表
---@param ui table 当前 UI 信息 { width: integer, height: integer }
---@return integer width 计算后的宽度
---@return integer height 计算后的高度
local function make_floating_popup_size(opts, ui)
  -- 取绝对值（负数仅用于决定锚点方向）
  local w = math.abs(opts.width)
  local h = math.abs(opts.height)

  -- 小于 1 视为屏幕占比，否则视为绝对字符数
  w = w < 1 and math.floor(ui.width * w + 0.5) or w
  h = h < 1 and math.floor(ui.height * h + 0.5) or h

  -- 确保不超出屏幕边界
  return math.min(w, ui.width), math.min(h, ui.height)
end

--- 计算窗口在屏幕中的位置
--- 支持数字（绝对定位）和字符快捷方式：
---   row: 't'(顶部) | 'c'(垂直居中) | 'b'(底部) | number
---   col: 'l'(左侧) | 'c'(水平居中) | 'r'(右侧) | number
---
--- 九宫格定位示意：
---   +------+------+------+
---   |  tl  |  tc  |  tr  |
---   +------+------+------+
---   |  cl  |  cc  |  cr  |
---   +------+------+------+
---   |  bl  |  bc  |  br  |
---   +------+------+------+
---@param opts table 包含 row, col, width, height 的配置表
---@param ui table 当前 UI 信息 { width: integer, height: integer }
---@return integer row 行位置
---@return integer col 列位置
local function get_position(opts, ui)
  -- 行位置映射表
  local row_map = {
    c = function() return math.floor((ui.height - opts.height) / 2 + 0.5) end, -- 居中
    t = function() return 0 end, -- 顶部
    b = function() return ui.height - 1 end, -- 底部
  }

  -- 列位置映射表
  local col_map = {
    c = function() return math.floor((ui.width - opts.width) / 2 + 0.5) end, -- 居中
    l = function() return 0 end, -- 左侧
    r = function() return ui.width end, -- 右侧
  }

  -- 数字直接使用，字符串查表计算，无效值默认为 0
  local row = type(opts.row) == 'number' and opts.row
    or (row_map[opts.row] and row_map[opts.row]() or 0)
  local col = type(opts.col) == 'number' and opts.col
    or (col_map[opts.col] and col_map[opts.col]() or 0)

  return row, col
end

--- 组装 nvim_open_win() 所需的完整配置表
--- 整合锚点、尺寸、位置等计算结果
---@param opts table 用户传入的配置选项
---@return table 可直接传给 nvim_open_win() 的配置表
local function make_floating_popup_options(opts)
  -- 获取当前 UI 尺寸信息，headless 模式下报错
  local uis = api.nvim_list_uis()
  assert(#uis > 0, 'No UI attached')
  local ui = uis[1]

  -- 深拷贝避免污染原始配置
  local conf = vim.deepcopy(opts)

  -- 依次计算锚点、尺寸、位置
  local anchor = conf.anchor or make_floating_popup_anchor(conf)
  conf.width, conf.height = make_floating_popup_size(conf, ui)
  local row, col = get_position(conf, ui)

  return {
    anchor = anchor,
    bufpos = conf.relative == 'win' and conf.bufpos or nil, -- 仅 relative='win' 时生效
    row = row,
    col = col,
    focusable = conf.focusable == nil and true or conf.focusable, -- 默认可聚焦
    relative = conf.relative or 'editor', -- 默认相对于编辑器
    style = 'minimal',
    width = conf.width,
    height = conf.height,
    border = conf.border or 'rounded',
    title = conf.title or '',
    title_pos = conf.title_pos or 'center', -- 标题默认居中
    zindex = conf.zindex or 50, -- 层叠顺序，数值越大越靠前
    noautocmd = conf.noautocmd == nil and false or conf.noautocmd,
  }
end

--- 浮动窗口对象
--- 封装了窗口和缓冲区的操作方法，支持链式调用
---@class FloatWin
---@field bufnr integer 关联的缓冲区编号
---@field winid integer 窗口 ID
local FloatWin = {}
FloatWin.__index = FloatWin

--- 检查窗口和缓冲区是否仍然有效
---@return boolean
function FloatWin:valid()
  return self.winid and api.nvim_win_is_valid(self.winid)
    and self.bufnr and api.nvim_buf_is_valid(self.bufnr)
end

--- 设置缓冲区选项
--- 支持单个设置和批量设置两种方式
--- 示例：
---   :bufopt('filetype', 'lua')                           -- 单个
---   :bufopt({ filetype = 'lua', modifiable = false })    -- 批量
---@param name string|table 选项名或键值对表
---@param value? any 选项值（批量模式下忽略）
---@return FloatWin self 支持链式调用
function FloatWin:bufopt(name, value)
  if type(name) == 'table' then
    for k, v in pairs(name) do
      api.nvim_set_option_value(k, v, { buf = self.bufnr })
    end
  else
    api.nvim_set_option_value(name, value, { buf = self.bufnr })
  end
  return self
end

--- 设置窗口选项
--- 用法与 bufopt 相同，窗口无效时静默跳过
---@param name string|table 选项名或键值对表
---@param value? any 选项值（批量模式下忽略）
---@return FloatWin self 支持链式调用
function FloatWin:winopt(name, value)
  if not self:valid() then return self end
  if type(name) == 'table' then
    for k, v in pairs(name) do
      api.nvim_set_option_value(k, v, { win = self.winid })
    end
  else
    api.nvim_set_option_value(name, value, { win = self.winid })
  end
  return self
end

--- 设置缓冲区内容
---@param lines string[] 要写入的文本行
---@param start_row? integer 起始行（默认 0）
---@param end_row? integer 结束行（默认 -1，即末尾）
---@return FloatWin self 支持链式调用
function FloatWin:set_lines(lines, start_row, end_row)
  api.nvim_buf_set_lines(self.bufnr, start_row or 0, end_row or -1, false, lines)
  return self
end

--- 动态调整窗口配置（大小、位置等）
--- 示例：:resize({ width = 40, height = 20 })
---@param opts table 要更新的窗口配置项
---@return FloatWin self 支持链式调用
function FloatWin:resize(opts)
  if not self:valid() then return self end
  local config = api.nvim_win_get_config(self.winid)
  api.nvim_win_set_config(self.winid, vim.tbl_extend('force', config, opts))
  return self
end

--- 关闭浮动窗口
--- 窗口已关闭或无效时静默跳过
function FloatWin:close()
  if self.winid and api.nvim_win_is_valid(self.winid) then
    api.nvim_win_close(self.winid, true) -- force=true 强制关闭
  end
  self.winid = nil
end

--- 获取缓冲区编号和窗口 ID
---@return integer bufnr 缓冲区编号
---@return integer winid 窗口 ID
function FloatWin:wininfo()
  return self.bufnr, self.winid
end

--- 创建浮动窗口
---
--- 使用示例：
---   -- 创建一个屏幕居中、占 80%×60% 的浮动窗口
---   local w = new_float({
---     width  = 0.8,         -- 屏幕宽度的 80%
---     height = 0.6,         -- 屏幕高度的 60%
---     row    = 'c',         -- 垂直居中
---     col    = 'c',         -- 水平居中
---     title  = ' My Float ',
---   }, true, true)
---
---   -- 链式操作
---   w:set_lines({ 'hello', 'world' })
---    :bufopt({ filetype = 'markdown', modifiable = false })
---    :winopt('winblend', 20)
---
---@param float_opt table 窗口配置选项
---   - bufnr?: integer       复用已有缓冲区（不传则自动创建）
---   - width: number          宽度（<1 为比例，>=1 为绝对值，负数改变锚点方向）
---   - height: number         高度（同上）
---   - row: string|number     行位置（'t'/'c'/'b' 或数字）
---   - col: string|number     列位置（'l'/'c'/'r' 或数字）
---   - 其他 nvim_open_win 支持的选项
---@param enter? boolean 是否进入窗口（默认 false）
---@param force? boolean 是否启用高级配置模式（比例尺寸、快捷定位等，默认 false）
---@return FloatWin 浮动窗口对象实例
local function new_float(float_opt, enter, force)
  -- 创建独立实例，避免状态污染
  local instance = setmetatable({}, FloatWin)

  -- 复用已有缓冲区或创建新的（unlisted, scratch）
  instance.bufnr = float_opt.bufnr or api.nvim_create_buf(false, false)
  float_opt.bufnr = nil -- bufnr 不是 nvim_open_win 的合法参数，移除

  -- force=true: 启用完整配置流程（支持比例尺寸、快捷定位等）
  -- force=false: 仅合并默认配置，直接透传给 nvim_open_win
  local win_config = force
    and make_floating_popup_options(float_opt)
    or vim.tbl_extend('force', DEFAULT_CONFIG, float_opt)

  -- 创建浮动窗口
  instance.winid = api.nvim_open_win(instance.bufnr, enter or false, win_config)

  return instance
end

return { new_float = new_float }

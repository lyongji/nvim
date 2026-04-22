-- 浮动终端模块
-- 功能：在浮动窗口中打开/关闭/切换终端，支持居中和侧边两种布局

local win = require('tool.window')
local api = vim.api

--- 终端状态
---@class TermState
---@field bufnr? integer 终端缓冲区编号
---@field winid? integer 浮动窗口 ID
local state = {}

--- 布局位置索引：0 = 居中（默认），1 = 右侧边栏
local layout_index = 0

--- 当前使用的浮动窗口配置
local float_opt = {}

--- 预定义布局方案
local LAYOUTS = {
  -- 右侧边栏：25% 宽，90% 高
  [1] = {
    width = 0.25,
    height = 0.9,
    title = ' 终端 ',
    relative = 'editor',
    row = 't',
    col = 'r',
  },
  -- 居中弹窗：70% 宽高（默认）
  [0] = {
    width = 0.7,
    height = 0.7,
    title = ' 终端 ',
    relative = 'editor',
    row = 'c',
    col = 'c',
  },

}
-- 获取跨平台 shell
---@return string
local function get_shell()
  if vim.o.shell and vim.o.shell ~= '' then
    return vim.o.shell
  end
  if vim.fn.has('win32') == 1 then
    return vim.fn.executable('pwsh') == 1 and 'pwsh'
      or vim.fn.executable('powershell') == 1 and 'powershell'
      or 'cmd.exe'
  end
  return os.getenv('SHELL') or '/bin/sh'
end
--- 关闭浮动终端窗口（保留缓冲区）
local function close_window()
  if state.winid and api.nvim_win_is_valid(state.winid) then
    api.nvim_win_close(state.winid, true)
  end
  state.winid = nil
end

--- 在浮动窗口中打开已有的终端缓冲区
---@param bufnr integer 终端缓冲区编号
local function open_window(bufnr)
  -- 清除 modified 标记，避免关闭时提示保存
  api.nvim_set_option_value('modified', false, { buf = bufnr })

  state.bufnr, state.winid = win
    .new_float(vim.tbl_extend('force', float_opt, { bufnr = bufnr }), true, true)
    :bufopt('bufhidden', 'hide') -- 窗口关闭时隐藏缓冲区而非删除
    :wininfo()

  vim.cmd('startinsert')
end

--- 创建新的终端实例
local function create_terminal()
  -- 如果窗口已打开，先关闭
  close_window()

  -- 创建浮动窗口
  state.bufnr, state.winid = win
    .new_float(float_opt, true, true)
    :bufopt('bufhidden', 'hide')
    :wininfo()

  -- 启动 shell 进程
  vim.fn.jobstart(get_shell(), {
    term = true,
    on_exit = function()
      -- 进程退出时清理状态
      close_window()
      state.bufnr = nil
    end,
  })
end

--- 切换浮动终端
--- 三种模式：
---   toggle_term()      → 打开/关闭终端（首次调用自动创建）
---   toggle_term('pos') → 在居中和侧边栏布局之间切换
---@param opt? string 操作类型，'pos' 表示切换布局位置
local function toggle_term(opt)
  -- 切换布局位置
  if opt == 'pos' then
    if not state.bufnr then return end -- 终端未创建，无需切换
    close_window()
    layout_index = 1 - layout_index -- 在 0 和 1 之间切换
    float_opt = LAYOUTS[layout_index]
    open_window(state.bufnr)
    return
  end

  -- 首次打开：创建终端
  if not state.bufnr then
    float_opt = LAYOUTS[0]
    create_terminal()
    return
  end

  -- 已有终端：切换显示/隐藏
  if state.winid then
    close_window()
  else
    open_window(state.bufnr)
  end
end

return { toggle_term = toggle_term }

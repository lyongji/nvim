-- 项目级便利贴模块 (极简稳健版)
local float_win = require('tool.依赖.window')
local api = vim.api
local fn = vim.fn

local state = { win = nil, side = 'r', file_path = nil, augroup = nil }

local function get_project_root()
  local git_dir = vim.fs.find('.git', { upward = true, path = fn.expand('%:p:h') })[1]
  return git_dir and fn.fnamemodify(git_dir, ':h') or fn.getcwd()
end

--- 获取或创建 Buffer，并绑定"离开即自动保存"的安全机制
local function get_buf(file_path)
  local bufnr = fn.bufnr(file_path)
  if bufnr == -1 then
    if fn.filereadable(file_path) == 0 then
      fn.writefile({ '# 📌 项目便签', '', '- [ ] 待办 1', '' }, file_path)
    end
    bufnr = fn.bufadd(file_path)
    fn.bufload(bufnr)
  end
  
  -- 核心：利用自动命令处理保存，杜绝手动保存引发的报错
  if not state.augroup then
    state.augroup = api.nvim_create_augroup('StickyNotes', { clear = true })
  end
  api.nvim_clear_autocmds({ group = state.augroup, buffer = bufnr })
  api.nvim_create_autocmd({ 'BufLeave', 'WinClosed' }, {
    group = state.augroup,
    buffer = bufnr,
    callback = function()
      if fn.getbufvar(bufnr, '&modified') == 1 then
        pcall(vim.cmd, 'silent! update') -- 仅在有修改时静默保存
      end
    end
  })
  
  return bufnr
end

local function close()
  if state.win and state.win:valid() then
    state.win:close() -- 关闭时无需管保存，BufLeave 已经处理了
  end
  state.win = nil
end

local function open(side)
  if state.win and state.win:valid() then close() end

  state.side = side or state.side
  state.file_path = get_project_root() .. '/.便签.md'
  local bufnr = get_buf(state.file_path)
  local name = fn.fnamemodify(get_project_root(), ':t')

  state.win = float_win.new_float({
    bufnr = bufnr, width = 0.3, height = 0.85, row = 'c', col = state.side,
    title = ' 📌 ' .. name .. ' ', border = 'rounded', zindex = 45,
  }, true, true)

  state.win
    :bufopt({ filetype = 'markdown', buftype = '', swapfile = false })
    :winopt({ winblend = 10, signcolumn = 'no', wrap = true, linebreak = true })

  -- 绑定ctr q 关闭
    vim.keymap.set('n', '<C-q>', close, { buffer = bufnr, noremap = true, silent = true })
end

--- 动作 1：打开/关闭
local function toggle()
  if state.win and state.win:valid() then close() else open() end
end

--- 动作 2：切换左右 (如果没开则直接开启)
local function switch()
  local next_side = state.side == 'l' and 'r' or 'l'
  open(next_side)
end

return { toggle = toggle, switch = switch }


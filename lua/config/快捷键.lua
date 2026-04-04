----------------------
-- 快捷键配置 --
----------------------
-- =======================================
-- 基础设置与 leader 键
-- ============================================================================
vim.g.mapleader = " "          -- 全局 leader 键设为空格
vim.g.maplocalleader = " "     -- 局部 leader 键

-- ============================================================================
-- 通用快捷键映射（不依赖特定插件）
-- ============================================================================
local map = vim.keymap.set

-- 退出插入模式
map("i", "jk", "<ESC>", { desc = "退出插入" })

-- 屏幕行移动（兼容 wrap 关闭的情况）
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "向下（屏幕行）" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "向上（屏幕行）" })

-- 移动行（Alt + j/k）
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "向下移动行" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "向上移动行" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "向下移动行（插入）" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "向上移动行（插入）" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "向下移动选中行" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "向上移动选中行" })

-- 缓冲区管理（未使用 bufferline 的额外操作）
map("n", "<leader>bd", function()
  local cur = vim.api.nvim_get_current_buf()
  local alt = vim.fn.bufnr("#")
  if alt > 0 and vim.api.nvim_buf_is_loaded(alt) then
    vim.cmd("buffer #")
  else
    vim.cmd("bnext")
  end
  vim.cmd("bdelete " .. cur)
end, { desc = "删除当前缓冲区" })
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and buf ~= current then
      vim.cmd("bdelete " .. buf)
    end
  end
end, { desc = "删除其他缓冲区" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "删除缓冲区并关闭窗口" })

-- Esc 清除搜索高亮
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Esc 并清除搜索高亮" })

-- 搜索导航优化
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "下一个搜索结果" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "上一个搜索结果" })

-- 快速保存
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "保存文件" })

-- 关键字帮助（恢复默认 K）
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "关键字帮助" })

-- 缩进保持选中
map("x", "<", "<gv")
map("x", ">", ">gv")

-- 快速添加注释行
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "下方添加注释行" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "上方添加注释行" })

-- 新建空白文件
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "新建文件" })

-- 切换位置列表 / 快速修复列表
map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success then vim.notify(err, vim.log.levels.ERROR) end
end, { desc = "位置列表" })
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success then vim.notify(err, vim.log.levels.ERROR) end
end, { desc = "快速修复列表" })
map("n", "[q", vim.cmd.cprev, { desc = "上一个快速修复项" })
map("n", "]q", vim.cmd.cnext, { desc = "下一个快速修复项" })

-- 诊断导航
local diagnostic_goto = function(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "显示光标诊断" })
map("n", "]d", diagnostic_goto(true), { desc = "下一个诊断" })
map("n", "[d", diagnostic_goto(false), { desc = "上一个诊断" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "下一个错误" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "上一个错误" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "下一个警告" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "上一个警告" })

-- 退出所有
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "退出所有" })

-- 窗口导航与拆分
map("n", "<C-h>", "<C-w>h", { desc = "左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "下方窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "上方窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "右侧窗口" })
map("n", "<leader>-", "<C-W>s", { desc = "水平拆分", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "垂直拆分", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "关闭窗口", remap = true })
map("n", "<leader>ww", "<C-w>w", { desc = "切换窗口焦点" })



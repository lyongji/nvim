
-- =====================================-- ============================================================================
-- Neovim 选项（编辑体验优化）
-- ============================================================================
-- 显示与界面
vim.opt.number = true          -- 绝对行号
vim.opt.relativenumber = true  -- 相对行号
vim.opt.cursorline = true      -- 高亮当前行
vim.opt.signcolumn = "yes"     -- 始终显示符号列
vim.opt.ruler = true           -- 状态栏显示光标位置
vim.opt.laststatus = 3         -- 全局状态栏
vim.opt.termguicolors = true   -- 启用真彩色
vim.opt.showmode = false       -- 不显示模式提示（--INSERT--）
vim.opt.colorcolumn = "80"     -- 第80列高亮
vim.opt.list = true            -- 显示不可见字符
vim.opt.listchars = {
  tab = '» ',
  trail = '·',
  nbsp = '␣'
}

-- 行为与交互
vim.opt.confirm = true         -- 退出前确认未保存修改
vim.opt.undofile = true        -- 持久化撤销
vim.opt.undolevels = 1000000   -- 最大撤销历史
vim.opt.mouse = "a"            -- 启用鼠标
vim.opt.wrap = false           -- 关闭自动换行
vim.opt.linebreak = false
vim.opt.scrolloff = 4          -- 光标上下保留4行
vim.opt.sidescrolloff = 8      -- 光标左右保留8列
vim.opt.winminwidth = 5        -- 最小窗口宽度
vim.opt.splitbelow = true      -- 水平拆分新窗口在下
vim.opt.splitright = true      -- 垂直拆分新窗口在右
vim.opt.splitkeep = "screen"   -- 拆分时保留窗口布局
vim.opt.virtualedit = "block"  -- 可视块模式允许移到行尾外
vim.opt.wildmode = "longest:full,full"
vim.opt.jumpoptions = "view"
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldtext = "v:lua.vim.fn.getline(v:foldstart) .. ' …'"

-- 缩进与格式
vim.opt.expandtab = true       -- 空格替代制表符
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.shiftround = true
vim.opt.smartindent = true
vim.opt.formatoptions = "jcroqlnt"

-- 搜索与替换
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "nosplit"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"

-- 语言与拼写
vim.opt.spelllang = { "en", "cjk" }

-- 大文件大小限制设置
vim.g.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB

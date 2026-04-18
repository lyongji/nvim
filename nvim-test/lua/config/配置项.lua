-- =====================================-- ============================================================================
-- Neovim 选项（编辑体验优化）
-- ============================================================================
-- 设置 Shell 程序
vim.o.shell = "pwsh"
vim.opt.shellcmdflag =
"-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();"
vim.opt.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
vim.opt.shellquote = ''
vim.opt.shellxquote = ''

-- 显示与界面
vim.opt.number = true -- 绝对行号
vim.opt.relativenumber = true -- 相对行号
vim.opt.cursorline = true -- 高亮当前行
vim.opt.signcolumn = "yes" -- 始终显示符号列（用于诊断、git标记等）
vim.opt.termguicolors = true -- 启用真彩色（需要终端支持）
vim.opt.colorcolumn = "80" -- 在第80列高亮显示，提示代码宽度限制
vim.opt.list = true -- 显示不可见字符（空格、制表符等）
vim.opt.listchars = { -- 不可见字符的显示样式
  tab = '» ', -- 制表符显示为 »
  trail = '·', -- 行尾多余空格显示为 ·
  nbsp = '␣' -- 不间断空格显示为 ␣
}
-- 状态栏与命令行
vim.opt.laststatus = 3   -- 完全隐藏状态栏
-- vim.opt.showmode = false -- 不显示 --INSERT-- 等模式提示
-- vim.opt.showcmd = false  -- 不显示正在输入的命令（解决 jk 闪烁）
-- vim.opt.cmdheight = 1    -- 命令行高度为0，彻底隐藏底部那行
-- vim.opt.ruler = false    -- 不显示光标位置信息

-- 行为与交互
vim.opt.confirm = true                 -- 退出前确认未保存修改
vim.opt.undofile = true                -- 持久化撤销历史（保存到文件）
vim.opt.undolevels = 1000000           -- 最大撤销历史记录数
vim.opt.mouse = "a"                    -- 启用鼠标支持（所有模式）
vim.opt.wrap = false                   -- 关闭自动换行，超出屏幕水平滚动
vim.opt.scrolloff = 4                  -- 光标上下保留4行，保持视觉上下文
vim.opt.sidescrolloff = 8              -- 光标左右保留8列，水平滚动时保持上下文
vim.opt.winminwidth = 5                -- 窗口最小宽度（字符数）
vim.opt.splitbelow = true              -- 水平拆分时新窗口在下方
vim.opt.splitright = true              -- 垂直拆分时新窗口在右侧
vim.opt.splitkeep = "screen"           -- 拆分窗口时保持当前屏幕布局
vim.opt.virtualedit = "block"          -- 可视块模式下允许光标移到行尾之外
vim.opt.wildmode = "longest:full,full" -- 命令行补全模式：最长匹配后打开菜单
vim.opt.jumpoptions = "view"           -- 跳转时保留视图位置


-- 缩进与格式
vim.opt.expandtab = true   -- 使用空格替代制表符
vim.opt.shiftwidth = 2     -- 自动缩进宽度为2空格
vim.opt.tabstop = 2        -- 制表符显示宽度为2空格
vim.opt.shiftround = true  -- 缩进时按shiftwidth的倍数取整
vim.opt.smartindent = true -- 智能自动缩进（适用于类C语言）
-- formatoptions 必须用 autocmd，否则被 ftplugin 覆盖
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    vim.opt_local.formatoptions = "jcroqlnt" -- 文本格式化选项：
  end,
})
-- j - 合并注释行时删除注释符
-- c - 自动格式化注释
-- r - 插入模式下回车自动插入注释符
-- o - 普通模式o/O自动插入注释符
-- q - 允许格式化注释
-- l - 长行不自动换行
-- n - 识别编号列表
-- t - 根据textwidth自动换行

-- 搜索与替换
vim.opt.ignorecase = true          -- 搜索时忽略大小写
vim.opt.smartcase = true           -- 智能大小写：搜索含大写字母时自动区分大小写
vim.opt.inccommand = "nosplit"     -- 实时预览替换结果（不分割窗口）
vim.opt.grepprg = "rg --vimgrep"   -- 设置grep程序为ripgrep（更快）
vim.opt.grepformat = "%f:%l:%c:%m" -- ripgrep输出格式解析

-- 语言与拼写
vim.opt.spelllang = { "en", "cjk" } -- 拼写检查语言：英文和中文（忽略中文）
-- vim.cmd.colorscheme("catppuccin")
-- 大文件大小限制设置
vim.g.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB，超过此大小视为大文件（用于禁用某些功能）

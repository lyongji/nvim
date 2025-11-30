-- 通用 Neovim 设置 --
----------------------
vim.opt.spelllang = "utf-8"
vim.opt.spelllang = { "en", "cjk" }             -- 拼写检查 中文 英文
vim.opt.linebreak = false                       -- 更适合中文换行
vim.g.mapleader = ' '                           -- 设置 leader 键为空格

-- 设置全局变量
vim.g.mapleader = ' '           -- 设置全局前缀键为空格
vim.g.maplocalleader = ' '      -- 设置本地前缀键为空格
vim.g.have_nerd_font = true     -- 启用 Nerd Font 支持
vim.g.markdown_folding = 1      -- 启用 Markdown 折叠
vim.g.simple_indicator_on = false -- 关闭简单指示器

-- 设置窗口边框样式
vim.o.winborder = 'single'

-- 缩进设置
vim.o.expandtab = true          -- 将 Tab 转换为空格
vim.o.tabstop = 2               -- Tab 宽度为 4 个空格
vim.o.shiftwidth = 2            -- 自动缩进宽度为 4 个空格

-- [[ 设置选项 ]]
-- 查看 `:help vim.opt`
-- 更多选项请查看 `:help option-list`

-- 启用真彩色支持
vim.opt.termguicolors = true

-- 设置行号显示
vim.opt.relativenumber = true   -- 显示相对行号
vim.opt.number = true           -- 显示绝对行号
vim.opt.signcolumn = 'yes'      -- 始终显示标记列
vim.opt.numberwidth = 4         -- 行号列宽度为 4 个字符

-- 启用软换行
vim.opt.wrap = true

-- 设置状态行显示模式（全局状态行）
vim.opt.laststatus = 3

-- 启用鼠标支持（可用于调整分割窗口大小等）
vim.opt.mouse = 'a'

-- 不显示模式指示器（因为已经在状态行中显示）
vim.opt.showmode = false

-- 同步系统剪贴板和 Neovim 剪贴板
-- 在 `UiEnter` 事件后设置以提升启动速度
-- 如果希望系统剪贴板保持独立，请移除此选项
-- 查看 `:help 'clipboard'`
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- 启用断行缩进
vim.opt.breakindent = true

-- 保存撤销历史
vim.opt.undofile = true

-- 搜索设置
vim.opt.ignorecase = true       -- 忽略大小写
vim.opt.smartcase = true        -- 如果包含大写字母则区分大小写

-- 默认保持标记列开启
vim.opt.signcolumn = 'auto'

-- 减少更新延迟时间
vim.opt.updatetime = 250

-- 禁用映射序列等待超时
vim.o.timeout = false

-- 设置 which-key 弹出延迟时间
vim.opt.timeoutlen = 300

-- 配置新分割窗口的打开方式
vim.opt.splitright = true       -- 垂直分割时在右侧打开
vim.opt.splitbelow = true       -- 水平分割时在下方打开

-- 设置 Neovim 如何显示空白字符
-- 查看 `:help 'list'` 和 `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { 
  tab = '» ',     -- Tab 显示为 » 
  trail = '·',    -- 行尾空格显示为 ·
  nbsp = '␣'      -- 不换行空格显示为 ␣
}

-- 实时预览替换效果
vim.opt.inccommand = 'split'

-- 高亮当前行
vim.opt.cursorline = true

-- 光标上下保留的最小屏幕行数
vim.opt.scrolloff = 5

-- 大文件大小限制设置
vim.g.bigfile_size = 1024 * 1024 * 1.5 -- 1.5 MB

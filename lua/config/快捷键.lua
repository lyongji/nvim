----------------------
-- 快捷键配置 --
----------------------


-- 撤销操作
vim.keymap.set({ 'n', 'v', 'i' }, '<C-z>', '<ESC>u<CR>', { desc = '撤销' })
-- 重做操作
vim.keymap.set({ 'n', 'v', 'i' }, '<C-y>', '<ESC>u<CR>', { desc = '重做' })


vim.keymap.set({ 'i' }, 'jk', '<ESC>', { desc = '退出i' })

-- 窗口切换
vim.keymap.set('n', '<leader>ww', '<C-w>w', { desc = '切换窗口焦点' })
-- 使用 <ctrl> hjkl 键移动窗口
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "移动到左侧窗口" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "移动到下方窗口" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "移动到上方窗口" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "移动到右侧窗口" })

-- 行移动
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc = '向下移动行' })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc = '向上移动行' })
vim.keymap.set('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = '向下移动行' })
vim.keymap.set('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = '向上移动行' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = '向下移动选中内容' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = '向上移动选中内容' })

-- 调整窗口大小
vim.keymap.set('n', '<C-Up>', ':resize +2<CR>', { desc = '增加窗口高度' })
vim.keymap.set('n', '<C-Down>', ':resize -2<CR>', { desc = '减少窗口高度' })
vim.keymap.set('n', '<C-Left>', ':vertical resize -2<CR>', { desc = '减少窗口宽度' })
vim.keymap.set('n', '<C-Right>', ':vertical resize +2<CR>', { desc = '增加窗口宽度' })

-- 取消高亮快捷键
vim.keymap.set('n', '//', '<cmd>nohlsearch<CR>', { desc = "取消搜索高亮" })
-- 系统剪贴板操作  配置项中已经开启同步系统剪贴板
-- vim.keymap.set({ 'n', 'v' }, '<leader>c', '"+y', { desc = '复制到系统剪贴板' })
-- vim.keymap.set({ 'n', 'v' }, '<leader>x', '"+d', { desc = '剪切到系统剪贴板' })
-- vim.keymap.set({ 'n', 'v' }, '<leader>p', '"+p', { desc = '从系统剪贴板粘贴' })

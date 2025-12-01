----------------------
-- 快捷键配置 --
----------------------
-- 退出 保存
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "退出所有" })
vim.keymap.set({ 'i' }, 'jk', '<ESC>', { desc = '退出i' })
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "保存文件" })
-- 注释
vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "在下方添加注释" })
vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "在上方添加注释" })

-- 窗口切换
vim.keymap.set('n', '<leader>ww', '<C-w>w', { desc = '切换窗口焦点' })


-- 行移动
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc = '向下移动行' })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc = '向上移动行' })
vim.keymap.set('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = '向下移动行' })
vim.keymap.set('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = '向上移动行' })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = '向下移动选中内容' })
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = '向上移动选中内容' })
-- 窗口操作
vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "水平分割窗口（下方）" })
vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "垂直分割窗口（右侧）" })
vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "关闭当前窗口" })
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

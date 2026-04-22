-- nvim 的原生功能实现
-- require('lua.tool.缩进线').setup({
--   char = '┊',
--   scope_char = '│',
--   exclude_ft = { 'help', 'dashboard', 'lazy', 'mason' },
-- })
-- ===
-- === 终端
-- ===
local term = require("tool.terminal")
-- 创建用户命令
vim.api.nvim_create_user_command('TermToggle', function()
  term.toggle_term()
end, { desc = '打开/关闭浮动终端' })

vim.api.nvim_create_user_command('TermPos', function()
  term.toggle_term('pos')
end, { desc = '切换终端布局位置' })


-- 绑定快捷键到命令
vim.keymap.set({ 'n', 't' }, '<A-d>', '<cmd>TermToggle<CR>')
vim.keymap.set({ 'n', 't' }, '<A-s>', '<cmd>TermPos<CR>')
-- 终端内快捷键
vim.keymap.set('t', '<C-q>', '<C-\\><C-n>', { desc = '退出终端插入模式' })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "退出终端插入模式" })

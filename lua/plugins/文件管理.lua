vim.pack.add({
  -- { src = 'https://github.com/nvim-mini/mini.pick' },   -- 文件/缓冲区选择器
  { src = 'https://github.com/nvim-mini/mini.files' },  -- 文件浏览器
})

----------------------
-- 插件配置 --
----------------------

-- mini.files 文件浏览器配置
require('mini.files').setup({
  windows = {
    preview = true, -- 打开预览窗口
  },
})

-- require('mini.pick').setup()

----------------------
-- 快捷键配置 --
----------------------
vim.keymap.set('n', '<leader>e', ':lua MiniFiles.open()<CR>', { desc = '打开文件浏览器' })
-- vim.keymap.set('n', '<leader>f', ':Pick files<CR>', { desc = '打开文件选择器' })
-- vim.keymap.set('n', '<leader>h', ':Pick help<CR>', { desc = '打开帮助选择器' })
-- vim.keymap.set('n', '<leader>b', ':Pick buffers<CR>', { desc = '打开缓冲区选择器' })
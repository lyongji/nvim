----------------------
-- 自动命令 --
----------------------
-- 保存前自动格式化
-- vim.api.nvim_create_autocmd('BufWritePre', {
--   callback = function()
--     vim.lsp.buf.format()
--   end,
--   pattern = '*',
-- })
--
-- 复制高亮提示
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = '高亮显示复制的文本',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 500 })
  end,
})

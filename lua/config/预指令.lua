----------------------
-- 自动命令 --
----------------------
-- 保存前自动格式化
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    vim.lsp.buf.format()
  end,
  pattern = '*',
})



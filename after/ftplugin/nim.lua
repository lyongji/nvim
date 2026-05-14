if vim.b.did_my_ftplugin then
  return
end
vim.b.did_my_ftplugin = true -- 防止重复加载
vim.lsp.enable("nim_langserver")

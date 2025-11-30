if vim.b.did_my_ftplugin then
  return
end
vim.b.did_my_ftplugin = true -- 防止重复加载
vim.lsp.enable 'lua_ls' -- 启用lua语言服务器
vim.lsp.config("lua_ls", {cmd = {"lua-language-server", "-E", "--locale=zh-cn"}}) -- 设置语言为中文
vim.lsp.enable 'stylua' -- 使用stylua格式化代码
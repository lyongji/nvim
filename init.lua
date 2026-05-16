--[[
     winget search ripgrep
     依赖：需要安装 television 二进制
     winget install alexpasmantier.television
--]]
--UI2 g< 开启  :messages
require('vim._core.ui2').enable(
  {
    enable=true,
  }
)

----------------------
-- 通用 Neovim 设置 --
----------------------
require("config.配置项")
require("config.快捷键")
require("config.预指令")
require("tool.init")
----------------------
-- 插件管理（vim.pack） --
----------------------
require("pack.plugins")
----------------------
-- lsp 配置 --
----------------------
-- ./lsp/
-- nvim 会在这个文件夹下查找你的lsp配置
-- 如果没有找到，会使用默认配置
-- after\ftplugin\lua.lua
-- 打开此 后缀名的文件 时，会自动加载执行这个文件.
-- 可以用来配置特定文件类型的LSP
-- 例如，配置lua的LSP

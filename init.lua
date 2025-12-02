--[[
Neovim 配置示例
注意事项：
1. 完整使用 mini.pick 需要安装 ripgrep，否则只能使用 git 查找。
   Windows 可通过 winget 安装：
     winget install BurntSushi.ripgrep.MSVC
   使用查找其他版本使用
     winget search ripgrep
2. 本配置使用 Neovim 0.12 内置 API（vim.pack）进行插件管理。
--]]
----------------------
-- 通用 Neovim 设置 --
----------------------
require("config.配置项")
require("config.快捷键")
require("config.预指令")
require("config.lsp")

----------------------
-- 插件管理（vim.pack） --
----------------------
-- 立即加载
require("plugins.主题色")
require("plugins.snacks") -- 仪表盘
require("plugins.文件管理")
require("plugins.图标和环绕")

require("plugins.treesitter") --读取缓存加载 语法高亮
require("plugins.whichkey") --快捷键提示
require("plugins.补全")
require("plugins.状态线") --读取缓存加载
require("plugins.xmake") --读取缓存加载
----------------------
-- LSP 配置 --
----------------------
-- ./lsp/
-- nvim 会在这个文件夹下查找你的lsp配置
-- 如果没有找到，会使用默认配置
-- after\ftplugin\lua.lua
-- 打开此 后缀名的文件 时，会自动加载执行这个文件.
-- 可以用来配置特定文件类型的LSP
-- 例如，配置lua的LSP

----------------------
-- 自动命令 --
----------------------

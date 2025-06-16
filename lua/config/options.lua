-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

local opt = vim.opt

opt.wrap = true
opt.spelllang = { "en", "cjk" } -- 拼写检查 中文 英文
opt.linebreak = false -- 更适合中文换行

vim.g.root_spec = { "cwd" }

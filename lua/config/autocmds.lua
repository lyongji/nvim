-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 使用中文文档
require("lspconfig")["lua_ls"].setup({
  cmd = { "lua-language-server", "-E", "--locale=zh-cn" },
})

-- xmake配合 状态栏插件
require("lualine").setup({
  sections = {
    lualine_y = {
      {
        function()
          if not vim.g.loaded_xmake then
            return ""
          end
          local Info = require("xmake.info")
          if Info.mode.current == "" then
            return ""
          end
          if Info.target.current == "" then
            return "Xmake: 未选择目标 "
          end
          return ("%s(%s)"):format(Info.target.current, Info.mode.current)
        end,
        cond = function()
          return vim.o.columns > 100
        end,
      },
    },
  },
})

-- 禁用xmake.lua 的格式化功能
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    -- 获取当前缓冲区文件名（不含路径）
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    -- 仅当文件名为 xmake.lua 时禁用格式化
    if filename == "xmake.lua" then
      vim.b.autoformat = false
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.pack.add({
  { src = 'https://github.com/nvim-lua/plenary.nvim' },  -- yazi.nvim 依赖
  { src = 'https://github.com/mikavilpas/yazi.nvim' }, -- 文件浏览器
})

----------------------
-- 插件配置 --
----------------------
vim.g.loaded_netrwPlugin = 1

-- Yazi 配置
vim.g.loaded_netrwPlugin = 1
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    require("yazi").setup({
      open_for_directories = true,
    })
  end,
})

----------------------
-- 快捷键配置 --
----------------------

-- 最简化的调用
vim.keymap.set("n", "<leader>e", function()
  -- 延迟加载
  local yazi = require("yazi")
  yazi.yazi()
end, { desc = "打开文件浏览器" })


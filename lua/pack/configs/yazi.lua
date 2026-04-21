vim.g.loaded_netrwPlugin = 1

local P = {
  name = "yazi.nvim",
  deps = { "plenary.nvim" },
}



----------------------
-- 插件配置 --
----------------------



----------------------
-- 快捷键配置 --
----------------------
vim.keymap.set("n", "<leader>e", function()
  -- 核心：直接调用引擎，把配置逻辑传进去
  -- 使用 快捷键时再加载
  PackUtils.load(P, function()
    require("yazi").setup({
      open_for_directories = true,
    })
  end)
  -- 提前触发 BufReadPost 的事件钩子，让 LSP 悄悄在后台 require 完毕
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("BufReadPost", { modeline = false })
  end)
  vim.cmd("Yazi")
end, { desc = "打开yazi" })

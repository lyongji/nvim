-- 内联诊断
local P = {
  name = "tiny-inline-diagnostic.nvim",
}

-- 打开文件时懒加载
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("TinyInlineDiagLoad", { clear = true }),
  once = true,
  callback = function()
    PackUtils.load(P, function()
      require("tiny-inline-diagnostic").setup({})
    end)
  end,
})

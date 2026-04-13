vim.pack.add({
  { src = "https://github.com/Mythos-404/xmake.nvim", name = "xmake" },
})
 
require("xmake").setup({lsp = { language = "zh-cn" }, })
 

-- 禁用 xmake.lua 的格式化功能
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    -- 获取当前缓冲区文件名（包含路径）
    local full_path = vim.api.nvim_buf_get_name(0)
    -- 获取文件名（不含路径）
    local filename = vim.fn.fnamemodify(full_path, ":t")
    -- 检查文件名是否为 xmake.lua
    if filename == "xmake.lua" then
      -- 禁用该缓冲区的自动格式化
      vim.b.autoformat = false
    end
  end,
})

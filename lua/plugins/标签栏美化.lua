vim.pack.add({
  {src = "https://github.com/akinsho/bufferline.nvim"},
})


-- ============================================================================
-- bufferline.nvim（标签栏美化）
-- ============================================================================
require("bufferline").setup({
  options = {
    close_command = function(bufnr) vim.cmd("bdelete " .. bufnr) end,
    right_mouse_command = function(bufnr) vim.cmd("bdelete " .. bufnr) end,
    diagnostics = "nvim_lsp",
    always_show_bufferline = true,
    diagnostics_indicator = function(_, _, diag)
      local icons = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      local ret = (diag.error and icons.Error .. diag.error .. " " or "") ..
                  (diag.warning and icons.Warn .. diag.warning or "")
      return vim.trim(ret)
    end,
    offsets = { { filetype = "neo-tree", text = "Neo-tree", highlight = "Directory", text_align = "left" } },
    get_element_icon = function(opts)
      local ok, devicons = pcall(require, "nvim-web-devicons")
      if ok then
        local icon = devicons.get_icon_by_filetype(opts.filetype)
        return icon
      end
      return ""
    end,
  }
})
-- bufferline 快捷键
vim.keymap.set("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", { desc = "切换固定标签" })
vim.keymap.set("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", { desc = "删除未固定标签" })
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "上一个缓冲区" })
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "下一个缓冲区" })



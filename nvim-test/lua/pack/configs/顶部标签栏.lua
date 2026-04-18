-- 标签栏 及其快捷键
local P = {
  name = "bufferline.nvim",
  deps = { "nvim-web-devicons" }, -- 确保图标库先加载
}

local map = vim.keymap.set

-- ==============================================================
-- 通用缓冲区快捷键（不依赖 bufferline，启动即可用）
-- ==============================================================

-- 删除当前缓冲区（智能切换到上一个或下一个）
map("n", "<leader>bd", function()
  local cur = vim.api.nvim_get_current_buf()
  local alt = vim.fn.bufnr("#")
  -- 优先切换到上一个访问过的缓冲区，否则切换到下一个
  if alt > 0 and vim.api.nvim_buf_is_loaded(alt) then
    vim.cmd("buffer #")
  else
    vim.cmd("bnext")
  end
  vim.cmd("bdelete " .. cur)
end, { desc = "删除当前缓冲区" })

-- 新建空白缓冲区
map("n", "<leader>bn", "<cmd>enew<cr>", { desc = "新建缓冲区" })

-- 删除当前缓冲区并关闭窗口（和 bd 的区别：窗口也会关闭）
map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "删除缓冲区并关闭窗口" })

-- ==============================================================
-- 懒加载触发器：首次打开或新建文件时加载 bufferline
-- ==============================================================
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  once = true,
  callback = function()
    PackUtils.load(P, function()
      -- ============================================================
      -- bufferline 标签操作快捷键
      -- ============================================================

      -- 固定/取消固定当前标签（固定的标签不会被批量关闭影响）
      map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "切换固定标签" })
      -- 关闭所有未固定的标签
      map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", { desc = "关闭未固定标签" })

      -- 标签间切换（按视觉顺序，非缓冲区编号顺序）
      map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "上个标签" })
      map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "下个标签" })

      -- 拖动标签位置
      map("n", "<leader>bh", "<cmd>BufferLineMovePrev<cr>", { desc = "左移标签" })
      map("n", "<leader>bl", "<cmd>BufferLineMoveNext<cr>", { desc = "右移标签" })

      -- 按视觉位置批量关闭标签
      map("n", "<leader>bH", "<cmd>BufferLineCloseLeft<cr>", { desc = "关闭左侧标签" })
      map("n", "<leader>bL", "<cmd>BufferLineCloseRight<cr>", { desc = "关闭右侧标签" })
      map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "关闭其他标签" })

      -- ============================================================
      -- bufferline 核心配置
      -- ============================================================
      require("bufferline").setup({
        options = {
          -- 视觉样式
          modified_icon = "",      -- 文件被修改时的标记图标
          buffer_close_icon = "×", -- 标签上的关闭按钮图标
          -- show_buffer_close_icons = false, -- 取消注释可隐藏关闭按钮

          -- 标签尺寸（紧凑布局）
          max_name_length = 14,   -- 文件名最大显示长度
          max_prefix_length = 13, -- 去重前缀最大长度
          tab_size = 10,          -- 标签最小宽度

          -- 指示器（当前标签的左侧竖线）
          indicator = {
            style = "none", -- 不显示指示器（可选: "icon", "underline"）
          },

          -- 始终显示标签栏（即使只有一个缓冲区）
          always_show_bufferline = true,

          -- LSP 诊断信息显示在标签上
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(_, _, diag)
            local icons = { Error = " ", Warn = " " }
            local ret = (diag.error and icons.Error .. diag.error .. " " or "")
                .. (diag.warning and icons.Warn .. diag.warning or "")
            return vim.trim(ret)
          end,
        },
      })
    end)
  end,
})

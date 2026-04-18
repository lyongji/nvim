-- 剪贴板 增强
local P = {
  name = "yanky.nvim",
}


-- ============================================================================
-- 剪贴板（OSC 52 协议，适用于远程环境）
-- ============================================================================

--- 从无名寄存器（unnamed register）读取内容，用于粘贴回调
local function paste_from_unnamed()
  local lines = vim.split(vim.fn.getreg(""), "\n", { plain = true })
  if #lines == 0 then lines = { "" } end
  return { lines, vim.fn.getregtype(""):sub(1, 1) }
end

-- 设置全局剪贴板为 OSC 52 协议
-- 复制（copy）通过 OSC 52 转义序列发送到终端，适用于 SSH 远程会话
-- 粘贴（paste）从无名寄存器读取，因为 OSC 52 协议本身不支持反向粘贴
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = { ["+"] = paste_from_unnamed, ["*"] = paste_from_unnamed },
}

-- 复制后自动同步到系统剪贴板，并高亮显示复制区域
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local ev = vim.v.event
    -- 仅当使用 y 操作且未指定寄存器时，才同步到 + 寄存器（系统剪贴板）
    if ev.operator == "y" and ev.regname == "" then
      vim.fn.setreg("+", ev.regcontents, ev.regtype)
    end
    -- 高亮显示刚刚复制的文本，持续 500 毫秒
    vim.highlight.on_yank({ timeout = 500 })
  end,
})

-- ============================================================================
-- yanky.nvim（增强剪贴板历史）
-- ============================================================================

PackUtils.load(P, function()
  require("yanky").setup({
    -- 不将系统剪贴板内容自动同步到 yanky 环形缓冲区
    system_clipboard = { sync_with_ring = false },
    ring = {
      -- 自动移除 Windows 风格的回车符（\r）
      permanent_wrapper = require("yanky.wrappers").remove_carriage_return,
    },
  })
  -- ---------------------------------------------------------------------------
  -- 缩进粘贴：粘贴后自动对齐当前缩进级别
  -- ---------------------------------------------------------------------------
  vim.keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "缩进粘贴到下方（按行）" })
  vim.keymap.set("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "缩进粘贴到上方（按行）" })
  vim.keymap.set("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "缩进粘贴到下方（按行）" })
  vim.keymap.set("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "缩进粘贴到上方（按行）" })

  -- ---------------------------------------------------------------------------
  -- 移位粘贴：粘贴后自动增加 / 减少一级缩进
  -- ---------------------------------------------------------------------------
  vim.keymap.set("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)", { desc = "粘贴到下方并右移缩进" })
  vim.keymap.set("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", { desc = "粘贴到下方并左移缩进" })
  vim.keymap.set("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", { desc = "粘贴到上方并右移缩进" })
  vim.keymap.set("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", { desc = "粘贴到上方并左移缩进" })

  -- ---------------------------------------------------------------------------
  -- 过滤粘贴：粘贴后通过 `=` 命令自动格式化（等同于 p 后执行 `=`]）
  -- ---------------------------------------------------------------------------
  vim.keymap.set("n", "=p", "<Plug>(YankyPutAfterFilter)", { desc = "粘贴到下方并自动格式化" })
  vim.keymap.set("n", "=P", "<Plug>(YankyPutBeforeFilter)", { desc = "粘贴到上方并自动格式化" })
end)

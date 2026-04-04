
vim.pack.add({
  {src = "https://github.com/gbprod/yanky.nvim"},
})

-- =================================-- ============================================================================
-- 剪贴板（OSC 52 协议，适用于远程环境）
-- ============================================================================
local function paste_from_unnamed()
  local lines = vim.split(vim.fn.getreg(""), "\n", { plain = true })
  if #lines == 0 then lines = { "" } end
  return { lines, vim.fn.getregtype(""):sub(1, 1) }
end

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = { ["+"] = paste_from_unnamed, ["*"] = paste_from_unnamed },
}

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local ev = vim.v.event
    if ev.operator == "y" and ev.regname == "" then
      vim.fn.setreg("+", ev.regcontents, ev.regtype)
    end
    vim.highlight.on_yank({ timeout = 500 })
  end,
})

-- ============================================================================
-- yanky.nvim（增强剪贴板历史）
-- ============================================================================
require("yanky").setup({
  system_clipboard = { sync_with_ring = false },
  ring = {
    permanent_wrapper = require("yanky.wrappers").remove_carriage_return,
  },
})

vim.keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)")
vim.keymap.set("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)")
vim.keymap.set("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)")
vim.keymap.set("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)")

vim.keymap.set("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)")
vim.keymap.set("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)")
vim.keymap.set("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)")
vim.keymap.set("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)")

vim.keymap.set("n", "=p", "<Plug>(YankyPutAfterFilter)")
vim.keymap.set("n", "=P", "<Plug>(YankyPutBeforeFilter)")
-- " line A → yy
-- " line B → yy  
-- " line A → yy

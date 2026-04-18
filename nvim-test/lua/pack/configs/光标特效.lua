local P = {
  name = "sphamba/smear-cursor.nvim",
}


-- ===========================================
-- 光标移动特效：smear-cursor.nvim
-- ============================================================================
PackUtils.load(P, function()
  require("smear_cursor").setup({ smear_between_buffers = true })
end)

return {

  {
    "monkoose/DoNe",
    lazy = true,
    -- optional configuration
    config = function()
      -- 可选：添加自定义键位映射
      vim.keymap.set("n", "<F5>", "<Cmd>DoNe build<CR>")
      --- ...
    end,
  },
}

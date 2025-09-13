return {
  {
    "liubianshi/cmp-lsp-rimels",
    keys = { { "<localleader>f", mode = "i" } },
    branch = "blink.cmp",
    config = function()
      vim.system({ "rime_ls", "--listen", "127.0.0.1:9257" }, { detach = true })
      require("rimels").setup({
        cmd = vim.lsp.rpc.connect("127.0.0.1", 9257),
        -- cmd = { vim.fn.expand("~/.local/bin/rime_ls")}, -- rime_ls 的路徑
        rime_user_dir = "~/.local/share/rime-ls", -- 属于此插件的配置地址
      })
    end,
  },
}
--keys = { start = ";f", stop = ";;", esc = ";j", undo = ";u" }, 默认快捷键
--  cmd = { "/sbin/rime_ls" },  rime_ls 程序的路径
--   rime_user_dir = "~/.local/share/rime-ls", 属于此插件的配置地址
--   shared_data_dir = "/usr/share/rime-data", 输入法方案路径
--

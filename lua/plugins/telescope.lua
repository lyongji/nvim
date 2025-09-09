return {

  {
    "nvim-telescope/telescope.nvim",

    keys = { -- 键位映射
      {
        "<leader>,",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "切换缓冲区",
      },
      { "<leader>/", LazyVim.pick("live_grep"), desc = "全局搜索（根目录）" },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "命令历史" },
      { "<leader><space>", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      -- 查找
      {
        "<leader>fb",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
        desc = "缓冲区列表",
      },
      { "<leader>fc", LazyVim.pick.config_files(), desc = "查找配置文件" },
      { "<leader>ff", LazyVim.pick("files"), desc = "查找文件（根目录）" },
      { "<leader>fF", LazyVim.pick("files", { root = false }), desc = "查找文件（当前工作目录）" },
      { "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "查找文件（Git 跟踪文件）" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "最近文件" },
      { "<leader>fR", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "最近文件（当前工作目录）" },
      -- Git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Git 提交记录" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Git 状态" },
      -- 搜索
      { '<leader>s"', "<cmd>Telescope registers<cr>", desc = "寄存器" },
      { "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "自动命令" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "当前缓冲区模糊查找" },
      { "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "命令历史" },
      { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "命令列表" },
      { "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "文档诊断" },
      { "<leader>sD", "<cmd>Telescope diagnostics<cr>", desc = "工作区诊断" },
      { "<leader>sg", LazyVim.pick("live_grep"), desc = "全局搜索（根目录）" },
      { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "全局搜索（当前工作目录）" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "帮助文档" },
      { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "高亮组搜索" },
      { "<leader>sj", "<cmd>Telescope jumplist<cr>", desc = "跳转列表" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "键位映射" },
      { "<leader>sl", "<cmd>Telescope loclist<cr>", desc = "位置列表" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "手册页" },
      { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "跳转到标记" },
      { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Vim 选项" },
      { "<leader>sR", "<cmd>Telescope resume<cr>", desc = "恢复上次搜索" },
      { "<leader>sq", "<cmd>Telescope quickfix<cr>", desc = "快速修复列表" },
      { "<leader>sw", LazyVim.pick("grep_string", { word_match = "-w" }), desc = "单词搜索（根目录）" },
      {
        "<leader>sW",
        LazyVim.pick("grep_string", { root = false, word_match = "-w" }),
        desc = "单词搜索（当前工作目录）",
      },
      { "<leader>sw", LazyVim.pick("grep_string"), mode = "v", desc = "选中文本搜索（根目录）" },
      {
        "<leader>sW",
        LazyVim.pick("grep_string", { root = false }),
        mode = "v",
        desc = "选中文本搜索（当前工作目录）",
      },
      { "<leader>uC", LazyVim.pick("colorscheme", { enable_preview = true }), desc = "配色方案（带预览）" },
      {
        "<leader>ss",
        function()
          require("telescope.builtin").lsp_document_symbols({
            symbols = LazyVim.config.get_kind_filter(),
          })
        end,
        desc = "跳转到符号（文档）",
      },
      {
        "<leader>sS",
        function()
          require("telescope.builtin").lsp_dynamic_workspace_symbols({
            symbols = LazyVim.config.get_kind_filter(),
          })
        end,
        desc = "跳转到符号（工作区）",
      },
    },
  },
}

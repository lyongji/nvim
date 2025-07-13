return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "none",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        -- fallback命令将运行下一个非闪烁键盘映射(回车键的默认换行等操作需要)
        ["<CR>"] = { "accept", "fallback" }, -- 更改成'select_and_accept'会选择第一项插入
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" }, -- 同时存在补全列表和snippet时，补全列表选择优先级更高

        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },

        ["<C-e>"] = { "snippet_forward", "select_next", "fallback" }, -- 同时存在补全列表和snippet时，snippet跳转优先级更高
        ["<C-u>"] = { "snippet_backward", "select_prev", "fallback" },
      },
      completion = {
        -- 示例：使用'prefix'对于'foo_|_bar'单词将匹配'foo_'(光标前面的部分),使用'full'将匹配'foo__bar'(整个单词)
        keyword = { range = "full" },
        -- 选择补全项目时显示文档(0秒延迟)
        documentation = { auto_show = true, auto_show_delay_ms = 0 },
        -- 不预选第一个项目，选中后自动插入该项目文本
        list = { selection = { preselect = false, auto_insert = false } },
        -- 针对菜单的外观配置
        -- menu = {
        -- 	min_width = 15,
        -- 	max_height = 10,
        -- 	border = "single", -- Defaults to `vim.o.winborder` on nvim 0.11+
        -- },
      },
      sources = {
        providers = {
          lsp = {
            transform_items = function(_, items)
              -- the default transformer will do this
              for _, item in ipairs(items) do
                if item.kind == require("blink.cmp.types").CompletionItemKind.Snippet then
                  item.score_offset = item.score_offset - 3
                end
              end
              -- you can define your own filter for rime item
              return items
            end,
          },
        },
      },
    },
  },
}

-- blink.cmp 安装补全配置以及触发加载
vim.pack.add({
  { src = 'https://github.com/saghen/blink.cmp',          version = vim.version.range('1.*') },
  { src = 'https://github.com/liubianshi/cmp-lsp-rimels', version = "blink.cmp",             name = "rimels", },
})

vim.opt.iskeyword = "_,49-57,A-Z,a-z" -- rime_ls 的配置
-- 插入和 cmd 时加载
vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
  group = vim.api.nvim_create_augroup("SetupCompletion", { clear = true }),
  once = true,
  callback = function()
    require("blink.cmp").setup({
      completion = {
        -- 示例：使用'prefix'对于'foo_|_bar'单词将匹配'foo_'(光标前面的部分),使用'full'将匹配'foo__bar'(整个单词)
        keyword = { range = "full" },                                      -- 关键字匹配范围
        -- 不预选第一个项目，选中后自动插入该项目文本
        list = { selection = { preselect = false, auto_insert = false } }, -- 补全列表设置
        documentation = {
          auto_show = true,                                                -- 自动显示文档
          window = {
            border = "single",                                             -- 边框样式
            scrollbar = false,                                             -- 禁用滚动条
          },
        },
        menu = {
          border = "single",      -- 菜单边框样式
          auto_show = true,       -- 自动显示补全菜单
          auto_show_delay_ms = 0, -- 自动显示延迟（毫秒）
          scrollbar = false,      -- 禁用滚动条
        },
      },
      keymap = {
        preset = "none",
        ["<C-x>"] = { "show", "show_documentation", "hide_documentation" }, -- Ctrl+空格：显示补全菜单、显示文档、隐藏文档
        -- fallback命令将运行下一个非闪烁键盘映射(回车键的默认换行等操作需要)
        ["<CR>"] = { "accept", "fallback" },                                -- 回车键：接受当前选中项并执行默认操作
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },    -- Shift+Tab：选择上一项、向后跳转代码片段
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },       -- Tab：选择下一项、向前跳转代码片段

        ["<C-b>"] = { "scroll_documentation_up", "fallback" },              -- Ctrl+B：向上滚动文档
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },            -- Ctrl+F：向下滚动文档

        ["<C-e>"] = { "snippet_forward", "select_next", "fallback" },       -- Ctrl+E：向前跳转代码片段、选择下一项
        ["<C-u>"] = { "snippet_backward", "select_prev", "fallback" },      -- Ctrl+U：向后跳转代码片段、选择上一项
      },
      signature = {
        enabled = true, -- 启用函数签名提示
      },
      cmdline = {
        completion = {
          menu = {
            auto_show = true, -- 在命令行中自动显示补全菜单
            -- border = "none",  -- 命令行补全菜单边框（已注释）
          },
        },
      },
      sources = {
        providers = {
          snippets = {
            score_offset = 1000,              -- 代码片段优先级偏移量
            should_show_items = function(ctx) -- 避免在 . " ' 字符后触发代码片段
              return ctx.trigger.initial_kind ~= "trigger_character"
            end,
          },
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
    })
  end,
})


local homepath = vim.env.HOME
-- 先添加 rime_ls 到环境变量中
vim.system({ "rime_ls", "--listen", "127.0.0.1:9257" }, { detach = true })
require("rimels").setup({
  cmd = vim.lsp.rpc.connect("127.0.0.1", 9257),
  -- cmd = { vim.fn.expand("E:\\app\\Rime\\weasel-0.17.4\\rime_ls.exe") }, -- rime_ls 的路徑
  rime_user_dir = homepath .. "/AppData/Roaming/Rime", -- 属于此插件的配置地址
})
--keys = { start = ";f", stop = ";;", esc = ";j", undo = ";u" }, 默认快捷键
--  cmd = { "/sbin/rime_ls" },  rime_ls 程序的路径
--   rime_user_dir = "~/.local/share/rime-ls", 属于此插件的配置地址
--   shared_data_dir = "/usr/share/rime-data", 输入法方案路径
--

-- === 自动补全插件 (Blink.cmp) ===

local P = {
  name = "blink.cmp",
  deps = { "friendly-snippets" }, -- 依赖：提供预置代码片段库
  -- build_cmd = "cargo build --release",
}

-- PackUtils.setup_listener(P.name, P.build_cmd)

vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter", "LspAttach" }, {
  once = true,
  callback = function()
    -- 调用引擎的 load 方法，把 setup 逻辑作为匿名函数传进去
    PackUtils.load(P, function()
      require("blink.cmp").setup({
        fuzzy = { -- 下载预编译的Fuzzy以节省空间
          prebuilt_binaries = {
            force_version = 'v1.*',
          },
        },
        cmdline = {
          -- 默认的cmdline回车按下执行命令
          -- keymap = { ["<CR>"] = { "select_and_accept", "fallback" } },
          completion = {
            list = { selection = { preselect = false, auto_insert = true } },        -- 不预选首项,自动插入匹配项
            menu = { auto_show = function() return vim.fn.getcmdtype() == ":" end }, -- 只在 : 命令模式显示
            ghost_text = { enabled = false },                                        -- 命令行不显示虚影文本
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
        completion = {
          keyword = { range = "full" }, -- 完整关键词匹配
          documentation = { auto_show = true, auto_show_delay_ms = 0 },
          list = {
            selection = {
              preselect = false,   -- 不自动预选第一项
              auto_insert = false, -- 不自动插入
            }
          },
          menu = {
            border = "single",      -- 菜单边框样式:单线边框
            auto_show = true,       -- 自动显示补全菜单
            auto_show_delay_ms = 0, -- 自动显示延迟（毫秒）
            -- scrollbar = false,              -- 禁用滚动条
          },
        },
        enabled = function()
          return not vim.tbl_contains({}, vim.bo.filetype)
              and vim.bo.buftype ~= "prompt"
              and vim.b.completion ~= false
        end,
        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = "mono",
        },
        sources = {
          default = { "buffer", "lsp", "path", "snippets", "pinyin" },
          -- 排序权重: buffer(5) > path(3) > lsp(2) > snippets(1)
          providers = {
              pinyin = {
                name = 'pinyin',
                module = 'tool.cmp_pinyin.blink',
                score_offset = -3,
              },
              buffer = { score_offset = 5 },
              path = { score_offset = 3 },
              lsp = { score_offset = 2 },
              snippets = { score_offset = 1 },
            -- cmdline = { -- 输入超过3个及以上字母才触发补全
            -- 	min_keyword_length = function(ctx)
            -- 		if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then return 3 end
            -- 		return 0
            -- 	end,
            -- },
          },
        },
      })
    end)
  end
})

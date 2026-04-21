-- === 自动配对括号/引号 (nvim-autopairs) ===
-- 输入 ( 自动补全 )，输入 " 自动补全 "，以此类推

if vim.g.vscode then return end

local P = { name = "nvim-autopairs" }

-- 进入插入模式时懒加载
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    PackUtils.load(P, function()
      require("nvim-autopairs").setup({

        -- =====================
        -- 启用/禁用控制
        -- =====================

        -- 控制是否对某个 buffer 启用，返回 false 则禁用
        -- enabled = function(bufnr) return true end,

        -- 在这些文件类型中完全禁用自动配对
        disable_filetype = {
          "markdown",            -- Markdown 中括号用途特殊
          "TelescopePrompt",     -- Telescope 搜索框
          "snacks_picker_input", -- Snacks 选择器输入框
        },

        disable_in_macro = true,        -- 录制/执行宏时禁用（避免干扰宏录制）
        disable_in_visualblock = false, -- 可视块模式插入时不禁用
        disable_in_replace_mode = true, -- 替换模式(R)下禁用

        -- =====================
        -- 智能判断
        -- =====================

        -- 使用 treesitter 检查配对上下文
        -- 例如：在字符串或注释内不自动补全括号
        check_ts = true,

        -- 光标右侧是以下字符时，不触发自动配对
        -- 避免 local t = sometable[| 这种情况重复补全
        ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],

        -- 检查同一行是否已有配对的右括号
        -- 避免 if (a == b)| 时再输入 ( 产生多余的 )
        enable_check_bracket_line = true,

        -- =====================
        -- 光标移动行为
        -- =====================

        -- 输入右括号时，如果右边已有 )，自动跳过而非重复插入
        -- 输入前: (hello|)  输入 )  →  (hello)|
        enable_moveright = true,

        -- =====================
        -- 引号与括号交互
        -- =====================

        -- 在引号后允许添加括号配对
        -- "hello"|  输入 (  →  "hello"(|)
        enable_afterquote = true,

        -- 在引号内部也启用括号配对
        -- "hello |"  输入 (  →  "hello (|)"
        enable_bracket_in_quote = true,

        -- =====================
        -- 按键映射
        -- =====================

        -- 映射回车键 <CR>
        -- 在括号间按回车自动展开并缩进:
        -- {|}  按回车  →  {
        --                    |
        --                  }
        map_cr = true,

        -- 映射退格键 <BS>
        -- 删除左括号时同时删除配对的右括号:
        -- (|)  按退格  →  |
        map_bs = true,

        -- 映射 <C-h> 删除配对（默认关闭）
        map_c_h = false,

        -- 映射 <C-w> 删除配对（默认关闭）
        map_c_w = false,

        -- =====================
        -- 其他
        -- =====================

        enable_abbr = false, -- 不触发 Vim 缩写功能
        break_undo = true,   -- 自动配对会打断撤销序列（每次配对是独立的撤销步骤）
      })
    end)
  end,
})

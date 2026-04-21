-- === mini ===
local P = {
  name = "mini.surround", -- 仓库名
}

-- 懒加载触发器
vim.api.nvim_create_autocmd({
  "UIEnter", -- vim.schedule(function()
}, {
  callback = function()
    vim.schedule(function()
      PackUtils.load(P, function()
        require("mini.surround").setup({
          mappings = {
            add = "sa",            -- 在普通模式和可视模式下添加环绕符号
            delete = "sd",         -- 删除环绕符号
            find = "sf",           -- 向右查找环绕符号
            find_left = "sF",      -- 向左查找环绕符号
            highlight = "sh",      -- 高亮显示环绕符号
            replace = "sr",        -- 替换环绕符号
            update_n_lines = "sn", -- 更新 `n_lines` 设置

            suffix_last = "l",     -- 使用“上一个”方法搜索时的后缀
            suffix_next = "n",     -- 使用“下一个”方法搜索时的后缀
          },
          custom_surroundings = {
            -- "b" = bold（粗体）
            -- 按 sb 添加: hello → **hello**
            -- 按 sd b 删除: **hello** → hello
            -- 按 sr b " 替换: **hello** → "hello"
            b = {
              -- input: 用 Lua 模式匹配已有的 **文字** 结构
              -- %*%* 匹配字面量 **（* 是特殊字符需要 % 转义）
              -- () 是捕获位置标记，告诉 mini.surround 内容的起止位置
              -- .- 是非贪婪匹配，匹配中间的任意内容
              -- 整体含义：匹配 **<内容>**，并标记出<内容>的边界
              input = { '%*%*().-()%*%*' },
              -- output: 添加或替换时，左边放 **，右边放 **
              output = { left = '**', right = '**' },
            },

            -- "i" = italic（斜体）
            -- 按 si 添加: hello → *hello*
            -- 按 sd i 删除: *hello* → hello
            i = {
              -- %*().-()%* 匹配 *<内容>*
              -- 注意：只有单个 *，和上面粗体的双 ** 区分开
              input = { '%*().-()%*' },
              output = { left = '*', right = '*' },
            },

            -- "c" = code（行内代码）
            -- 按 sc 添加: hello → `hello`
            -- 按 sc d 删除: `hello` → hello
            c = {
              -- `().-()`  匹配 `<内容>`
              -- 反引号不是 Lua 模式特殊字符，不需要转义
              input = { '`().-()`' },
              output = { left = '`', right = '`' },
            },
          }
        })
      end)
    end)
  end
})

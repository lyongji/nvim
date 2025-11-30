vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.icons" },    -- 图标
  { src = "https://github.com/nvim-mini/mini.surround" }, -- 标点 包围功能包
})

----------------------
-- 插件配置 --
----------------------
require("mini.icons").setup({
  style = "glyph",
  file = {
    README = { glyph = "󰆈", hl = "MiniIconsYellow" },
    ["README.md"] = { glyph = "󰆈", hl = "MiniIconsYellow" },
  },
  filetype = {
    bash = { glyph = "󱆃", hl = "MiniIconsGreen" },
    sh = { glyph = "󱆃", hl = "MiniIconsGrey" },
    toml = { glyph = "󱄽", hl = "MiniIconsOrange" },
  },
})

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
})
----------------------

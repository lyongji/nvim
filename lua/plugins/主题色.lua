-- 使用 Neovim 内置包管理器添加 Catppuccin 主题插件
-- 注意：这行代码可能不适用于所有插件管理器，通常使用 Packer/Lazy 等
vim.pack.add({
	{ src = "https://github.com/Mofiqul/dracula.nvim" },  })


-- ============================================================================
-- 主题：dracula.nvim（自定义配色）
-- ============================================================================
require("dracula").setup({
  colors = {
    bg = "#29202B", fg = "#F7F7F1",
    red = "#FF947F", orange = "#FFC97F", yellow = "#FEFF7F",
    green = "#8AFF7F", cyan = "#7FFFE9", blue = "#7FBFFF",
    pink = "#FF7FBF", purple = "#947FFF",
    shadow = "#000000", darken = "#212121",
    selection = "#534157", comment = "#9E6FA8",
    visual = "#492F4F", stack = "#E77FFF",
    bright_red = "#FFBFB2", bright_orange = "#FFDFB2",
    bright_yellow = "#FFFFB2", bright_green = "#B8FFB2",
    bright_cyan = "#B2FFF2", bright_blue = "#B2D8FF",
    bright_pink = "#FFB2D8", bright_purple = "#BFB2FF",
    bright_white = "#FFFFFF",
    white = "#F7F7F1", black = "#000000",
    menu = "#241C25", gutter_fg = "#84568F", nontext = "#584D5A",
  },
  transparent_bg = false,
  overrides = {
    NormalFloat = { bg = "#241C25" },
    FloatBorder = { fg = "#BFB2FF", bg = "#241C25" },
    NoiceCmdlinePopupBorder = { fg = "#BFB2FF" },
  },
})
vim.cmd.colorscheme("dracula")


-- 设置状态线背景为透明
vim.cmd.hi("statusline guibg=NONE")

-- 设置注释样式（去除斜体）
vim.cmd.hi("Comment gui=none")

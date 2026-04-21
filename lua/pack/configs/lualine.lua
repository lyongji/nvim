-- === 底部状态栏 ===

local P = {
  name = "lualine.nvim",
  deps = { "nvim-tree/nvim-web-devicons" },
}

PackUtils.load(P, function()
  -- ==================== 【动态融合主题：让状态栏与编辑器背景无缝衔接】 ====================
  -- 获取当前编辑器 Normal 高亮组的背景色
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  -- 如果是透明背景 bg 为 nil，赋值 "NONE"；否则转换为 "#RRGGBB" 格式
  local editor_bg = normal_hl.bg and string.format("#%06x", normal_hl.bg) or "NONE"

  -- 加载 Lualine 自动主题（自动提取当前配色方案的前景色）
  local blended_theme = require("lualine.themes.auto")

  -- 遍历所有模式（normal/insert/visual...）和区块（a/b/c...）
  -- 将背景色统一替换为编辑器背景色，实现"融合"效果
  for _, mode in pairs(blended_theme) do
    for _, section in pairs(mode) do
      if type(section) == "table" then
        section.bg = editor_bg
      end
    end
  end
  -- =====================================================================================

  require("lualine").setup({
    options = {
      theme = blended_theme,                              -- 使用融合主题
      globalstatus = true,                                -- 全局唯一状态栏（多窗口共享）
      always_divide_middle = false,                       -- 左右区块不强制居中分隔
      component_separators = { left = "", right = "" },   -- 组件间无分隔符
      section_separators = { left = "", right = "" },     -- 区块间无分隔符
    },

    sections = {
      -- ══════════════ 左侧 ══════════════
      lualine_a = {},                                     -- 留空（不显示模式块）
      lualine_b = {
        "branch",                                         -- Git 分支名
        "diff",                                           -- Git 增删改统计
        "diagnostics",                                    -- LSP 诊断（错误/警告/提示）
      },
      lualine_c = {
        {
          "filename",                                     -- 文件名
          path = 1,                                       -- 显示相对路径（0=仅文件名 1=相对 2=绝对）
          symbols = {
            modified = " ●",                              -- 已修改标记
            readonly = " ",                              -- 只读标记
            unnamed = "[无名]",                           -- 无名缓冲区
            newfile = "[新建]",                           -- 新文件
          },
        },
        {
          "lsp_status",                                   -- LSP 服务器状态
          color = { fg = "#6C6E81" },                     -- 灰色，不抢眼
        },
      },

      -- ══════════════ 右侧 ══════════════
      lualine_x = {
        -- 文件编码（utf-8 时隐藏，只显示非常规编码如 GBK）
        {
          "encoding",
          fmt = function(str)
            if str == "utf-8" then return "" end
            return str:upper()                            -- 非 utf-8 醒目大写显示
          end,
        },
        -- 文件格式（unix 时隐藏，只显示 dos/mac）
        {
          "fileformat",
          fmt = function(str)
            if str == "unix" then return "" end
            return str
          end,
        },
        "filetype",                                       -- 文件类型图标 + 名称
      },

      -- Xmake 构建状态
      lualine_y = {
        {
          function()
            if not vim.g.loaded_xmake then return "" end
            local Info = require("xmake.info")
            if Info.mode.current == "" then return "" end
            if Info.target.current == "" then return "Xmake: 无目标" end
            return ("%s(%s)"):format(Info.target.current, Info.mode.current)
          end,
          icon = "🛠",                                     -- Xmake 图标
          cond = function()
            return vim.o.columns > 100                    -- 窗口宽度 > 100 才显示（避免窄屏拥挤）
          end,
        },
      },

      lualine_z = {
        -- 光标位置：行号:列号（总行数）
        {
          function()
            local line = vim.fn.line(".")                 -- 当前行号
            local col = vim.fn.col(".")                   -- 当前列号
            local total = vim.fn.line("$")                -- 总行数
            return string.format("%d:%d  %d", line, col, total)
          end,
          icon = "",                                     -- 位置图标
        },
        "progress",                                       -- 文件位置百分比（42%）
      },
    },

    -- ══════════════ 非活动窗口状态栏（globalstatus=true 时可选） ══════════════
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { { "filename", path = 1 } },          -- 仅显示文件名
      lualine_x = { "location" },                        -- 仅显示位置
      lualine_y = {},
      lualine_z = {},
    },
  })
end)

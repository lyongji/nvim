-- === 代码格式化 (conform.nvim) ===

local P = {
  name = "conform.nvim",
  deps = { "mason.nvim", "mason-registry" },
}

-- =========================================================================
-- 文件类型 → 格式化工具映射表
-- =========================================================================
local formatters_by_ft = {
  python   = { "isort", "black" },    -- Python：导入排序 + 代码格式化
  toml     = { "templ" },             -- TOML 配置文件
  sh       = { "shfmt" },             -- Shell 脚本
  zsh      = { "shfmt" },             -- Zsh 脚本（复用 shfmt）
  markdown = { "deno_fmt_markdown" }, -- Markdown（自定义缩进宽度）
  c        = { "clang-format" },      -- C
  cpp      = { "clang-format" },      -- C++
  lua      = { "stylua" },            -- lua
}

-- 工具名 → 实际可执行文件名的映射（名称不一致时需要手动指定）
local real_executable_map = {
  deno_fmt          = "deno",
  deno_fmt_markdown = "deno",
  ["clang-format"]  = "clang-format",
}

-- =========================================================================
-- 辅助函数：从指定文件类型的配置中提取所有工具名称（去重）
-- =========================================================================
local function get_ensure_installed_for_ft(ft, ft_table)
  local tools = {}
  local cfg = ft_table[ft]
  if type(cfg) == "table" then
    for _, item in ipairs(cfg) do
      if type(item) == "string" then
        tools[item] = true
      end
    end
  elseif type(cfg) == "string" then
    tools[cfg] = true
  end
  local list = {}
  for tool in pairs(tools) do
    table.insert(list, tool)
  end
  return list
end

-- =========================================================================
-- 快捷键懒加载：按下 <leader>f 时才激活格式化插件
-- =========================================================================
vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  -- 首次按下时加载并初始化 conform.nvim
  PackUtils.load(P, function()
    require("conform").setup({
      formatters_by_ft = formatters_by_ft,
      formatters = {
        -- Markdown 格式化：继承 deno_fmt，但使用 4 空格缩进
        deno_fmt_markdown = {
          inherit = "deno_fmt",
          append_args = { "--indent-width", "4" },
        },
      },
    })
  end)

  -- 检测当前文件类型所需的格式化工具是否已安装
  local ft = vim.bo.filetype
  local raw_tools = get_ensure_installed_for_ft(ft, formatters_by_ft)
  local need_install = false

  for _, raw_tool in ipairs(raw_tools) do
    -- 查找实际可执行文件名
    local real_tool = real_executable_map[raw_tool] or raw_tool
    -- 如果系统中找不到该工具，尝试通过 Mason 安装
    if vim.fn.executable(real_tool) == 0 then
      need_install = true
      local registry = require("mason-registry")
      if not registry.is_installed(real_tool) then
        vim.notify("⬇️ 正在安装格式化工具: " .. real_tool, vim.log.levels.INFO)
        registry.get_package(real_tool):install()
      end
    end
  end

  if need_install then
    -- 工具安装中，提示用户稍后重试
    vim.notify("⏳ 格式化工具正在后台安装，请稍后重试...", vim.log.levels.WARN)
  else
    -- 所有工具就绪，执行异步格式化
    require("conform").format({ async = true, lsp_fallback = true })
  end
end, { desc = "格式化代码（自动检测）" })

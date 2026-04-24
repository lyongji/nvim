-- === LSP 核心配置 (Lspconfig + Mason) ===

-- 环境探测：判断 CPU 架构，决定安装哪些 LSP
local arch = jit and jit.arch or ""
local is_arm = arch:match("arm") or arch:match("aarch64")
-- 默认安装的lsp
local servers = {
  "lua_ls",
  "clangd",
  "pylsp",
}
-- 如果不是 ARM 架构（即 x86_64），才安装这些额外 LSP
if not is_arm then
  vim.list_extend(servers, { "marksman" })
end

-- 插件配置清单
local P = {
  name = "nvim-lspconfig",
  deps = { "mason.nvim", "mason-lspconfig.nvim", "inlay-hints.nvim" },
}

-- =========================================================================
-- 全局快捷键映射（不依赖插件加载，随时可用）
-- =========================================================================
local map = vim.keymap.set

-- 文档与跳转
map("n", "<leader>ch", vim.lsp.buf.hover, { desc = "悬停文档" })
map("n", "gd", vim.lsp.buf.definition, { desc = "跳转到定义" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "跳转到声明" })
map("n", "go", vim.lsp.buf.type_definition, { desc = "跳转到类型定义" })
-- 跳回（Neovim 内置跳转列表，不依赖 LSP）
-- "<C-o>", { desc = "跳回上一个位置" })
-- "<C-i>", { desc = "跳到下一个位置" })
-- 重构
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "变量重命名" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "代码操作（修复建议）" })

-- 诊断导航 跳转
local diagnostic_goto = function(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
-- 切换窗口焦点 可以进去复制
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "显示光标诊断" })
map("n", "]d", diagnostic_goto(true), { desc = "下个诊断" })
map("n", "[d", diagnostic_goto(false), { desc = "上个诊断" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "下个错误" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "上个错误" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "下个警告" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "上个警告" })
-- 函数首尾跳转
local function jump_to_function(to_end)
  local params = { textDocument = vim.lsp.util.make_text_document_params() }
  local responses = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
  if not responses then return end
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local function find_symbol(symbols)
    for _, s in ipairs(symbols) do
      local range = s.range or (s.location and s.location.range)
      if range and line >= range.start.line and line <= range["end"].line then
        if s.children then
          local child = find_symbol(s.children)
          if child then return child end
        end
        return s
      end
    end
  end
  for _, resp in pairs(responses) do
    local sym = find_symbol(resp.result or {})
    if sym and sym.range then
      local target = to_end and sym.range["end"].line or sym.range.start.line
      vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
      return
    end
  end
end
map("n", "[f", function() jump_to_function(false) end, { desc = "跳到函数头" })
map("n", "]f", function() jump_to_function(true) end, { desc = "跳到函数尾" })
-- =========================================================================
-- LspAttach: LSP 附加后的 buffer 级配置
-- =========================================================================
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspFeatures", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end

    -- 代码折叠
    if client:supports_method("textDocument/foldingRange") then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
  end,
})

-- =========================================================================
-- 懒加载触发器：首次打开文件时加载 LSP
-- =========================================================================
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("LspSetup", { clear = true }),
  once = true, -- 只需加载一次
  callback = function()
    PackUtils.load(P, function()
      -- === 基础依赖初始化 (Mason) ===
      require("mason").setup()
      require("mason-lspconfig").setup({ ensure_installed = servers, })
      require("inlay-hints").setup()
      -- === 内联提示（inlay hints）样式 ===
      vim.api.nvim_set_hl(0, "LspInlayHint", {
        fg = "#7a828e", -- 灰色幽灵文本
        italic = true,  -- 斜体
      })

      -- 切换 inlay hints 的快捷键
      map("n", "<leader>ci", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, { desc = "切换内联提示" })

      -- === 全局诊断设置 ===
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN]  = "▲",
            [vim.diagnostic.severity.HINT]  = "⚑",
            [vim.diagnostic.severity.INFO]  = "»",
          },
        },
      })

      -- =================================================================
      -- 特定 LSP 配置（Neovim 0.11+ vim.lsp.config 语法）
      -- =================================================================

      -- Python (pylsp) + uv 虚拟环境自适应
      vim.lsp.config("pylsp", {
        on_init = function(client)
          local root_dir = client.config.root_dir
          if root_dir then
            local venv_python = root_dir .. "/.venv/bin/python"
            if vim.fn.filereadable(venv_python) == 1 then
              client.config.settings.pylsp.plugins.jedi.environment = venv_python
              client.notify("workspace/didChangeConfiguration", {
                settings = client.config.settings,
              })
            end
          end
          return true
        end,
        settings = {
          pylsp = { plugins = { jedi = { environment = nil } } },
        },
      })

      -- Lua (lua_ls)
      vim.lsp.config("lua_ls", {
        cmd = { "lua-language-server", "-E", "--locale=zh-cn" },
        settings = {
          ["Lua"] = {
            hint = { enable = true },
            diagnostics = {
              globals = { "vim", "require", "opts", "PackUtils", "jit" },
            },
          },
        },
      })

      -- C/C++ (clangd)
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",          -- 后台索引，加速大项目跳转
          "--clang-tidy",                -- 启用 clang-tidy 静态分析
          "--header-insertion=iwyu",     -- 自动插入缺失的头文件
          "--completion-style=detailed", -- 补全项显示详细信息
          "--function-arg-placeholders", -- 函数补全时插入参数占位符
          "--fallback-style=llvm",       -- 无 .clang-format 时使用 LLVM 风格
        },
        -- clangd 内置 inlay hints，无需额外配置
        init_options = {
          clangdFileStatus = true, -- 在状态栏显示文件解析状态
        },
      })

      -- 启用所有配置的 LSP 服务器
      for _, server in ipairs(servers) do
        vim.lsp.enable(server)
      end
    end)
  end,
})

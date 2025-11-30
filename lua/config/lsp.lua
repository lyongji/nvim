-- 添加插件到包管理器
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },  -- Mason: LSP、DAP、linter、formatter 的包管理器
  { src = "https://github.com/neovim/nvim-lspconfig" }, -- nvim-lspconfig: Neovim 的 LSP 配置
})

-- 设置 Mason 插件
require("mason").setup()

-- 启用 clangd LSP 服务器
vim.lsp.enable("clangd")

-- 创建自动命令组，当 LSP 附加到缓冲区时执行配置
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("SetupLSP", {}),
  callback = function(event)
    -- 获取当前连接的 LSP 客户端
    local client = assert(vim.lsp.get_client_by_id(event.data.client_id))

    -- [代码内联提示配置]
    -- 检查客户端是否支持内联提示功能
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      -- 设置切换内联提示的快捷键
      -- <leader>th: 切换显示/隐藏代码内联提示（如类型提示、参数名称等）
      vim.keymap.set('n', '<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, { buffer = event.buf, desc = 'LSP: 切换内联提示' })
    end

    -- [代码折叠配置]
    -- 检查客户端是否支持代码折叠范围功能
    if client and client:supports_method 'textDocument/foldingRange' then
      local win = vim.api.nvim_get_current_win()
      -- 设置使用 LSP 提供的折叠表达式
      -- 让代码折叠基于语义而不是缩进
      vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end

    -- [LSP 快捷键映射]
    -- 格式化代码快捷键: <leader>lf
    vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = '格式化文档'} )

    -- 跳转到定义: gd
    -- 使用自定义函数，如果没有找到定义则显示通知
    -- 如果找到定义则使用 snacks 插件的选择器显示
    vim.keymap.set("n", "gd", function()
      local params = vim.lsp.util.make_position_params(0, "utf-8")
      vim.lsp.buf_request(0, "textDocument/definition", params, function(_, result, _, _)
        if not result or vim.tbl_isempty(result) then
          vim.notify("未找到定义", vim.log.levels.INFO)
        else
          require("snacks").picker.lsp_definitions()
        end
      end)
    end, { buffer = event.buf, desc = "LSP: 跳转到定义" })

    -- 跳转到定义（智能分割窗口）: gD
    -- 根据当前窗口尺寸智能选择水平或垂直分割
    vim.keymap.set("n", "gD", function()
      local win = vim.api.nvim_get_current_win()
      local width = vim.api.nvim_win_get_width(win)   -- 获取窗口宽度
      local height = vim.api.nvim_win_get_height(win) -- 获取窗口高度

      -- 使用 tmux 的分割公式: 8 * 宽度 - 20 * 高度
      -- 如果值为负，说明垂直空间更充足，使用水平分割
      -- 如果值为正，说明水平空间更充足，使用垂直分割
      local value = 8 * width - 20 * height
      if value < 0 then
        vim.cmd("split")  -- 水平分割
      else
        vim.cmd("vsplit") -- 垂直分割
      end

      vim.lsp.buf.definition() -- 跳转到定义
    end, { buffer = event.buf, desc = "LSP: 跳转到定义 (分屏)" })

    -- 跳转到当前函数的开头: [f
    -- 通过文档符号查询找到当前光标所在的函数，并跳转到其开始位置
    local function jump_to_current_function_start()
      local params = { textDocument = vim.lsp.util.make_text_document_params() }
      local responses = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
      if not responses then return end

      local pos = vim.api.nvim_win_get_cursor(0)
      local line = pos[1] - 1 -- 转换为 0-based 索引

      -- 递归查找包含当前行的符号
      local function find_symbol(symbols)
        for _, s in ipairs(symbols) do
          local range = s.range or (s.location and s.location.range)
          if range and line >= range.start.line and line <= range["end"].line then
            -- 如果有子符号，继续在子符号中查找
            if s.children then
              local child = find_symbol(s.children)
              if child then return child end
            end
            return s
          end
        end
      end

      -- 遍历所有 LSP 响应
      for _, resp in pairs(responses) do
        local sym = find_symbol(resp.result or {})
        if sym and sym.range then
          -- 跳转到符号开始位置（转换为 1-based 索引）
          vim.api.nvim_win_set_cursor(0, { sym.range.start.line + 1, 0 })
          return
        end
      end
    end
    vim.keymap.set("n", "[f", jump_to_current_function_start, { desc = "跳转到当前函数头" })

    -- 跳转到当前函数的结尾: ]f
    -- 与跳转到开头类似，但是跳转到函数的结束位置
    local function jump_to_current_function_end()
      local params = { textDocument = vim.lsp.util.make_text_document_params() }
      local responses = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
      if not responses then return end

      local pos = vim.api.nvim_win_get_cursor(0)
      local line = pos[1] - 1

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
          -- 跳转到符号结束位置（转换为 1-based 索引）
          vim.api.nvim_win_set_cursor(0, { sym.range["end"].line + 1, 0 })
          return
        end
      end
    end
    vim.keymap.set("n", "]f", jump_to_current_function_end, { desc = "跳转到当前函数尾" })
  end,
})

-- 注释掉的补全选项配置
-- vim.cmd([[set completeopt+=menuone,noselect,popup]])
-- 这行配置如果取消注释，会设置补全选项：
-- menuone: 即使只有一个匹配项也显示补全菜单
-- noselect: 不自动选择第一个匹配项
-- popup: 使用弹出窗口显示补全信息


-- LSP 诊断显示配置
vim.diagnostic.config({ virtual_text = true }) -- 行内文本提示

-- LSP 快捷键
vim.keymap.set('n', 'gs', vim.lsp.buf.declaration, { desc = '跳转到声明' })
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = '跳转到实现' })
vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = '查找引用' })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = '重命名符号' })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = '代码操作' })

-- 快速跳转诊断
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump({ wrap = true, count = -1 })
end, { desc = '上一个诊断' })
vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump({ wrap = true, count = 1 })
end, { desc = '下一个诊断' })

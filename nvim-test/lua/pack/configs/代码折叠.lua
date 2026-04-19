-- === 折叠插件 (nvim-ufo) ===

-- =========================================================================
-- 折叠相关全局设置
-- =========================================================================
vim.o.foldcolumn = "0"    -- 不显示折叠列（避免左侧出现奇怪的数字）
vim.o.foldlevel = 99      -- 默认展开所有折叠（ufo 需要较大值）
vim.o.foldlevelstart = 99 -- 打开文件时默认展开所有折叠
vim.o.foldenable = true   -- 启用折叠功能

local P = {
  name = "nvim-ufo",
  deps = { "promise-async" }, -- ufo 依赖的异步库
}

-- =========================================================================
-- 懒加载触发器：UI 就绪后加载
-- =========================================================================
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    -- 延迟到下一帧执行，确保 LSP 等已初始化
    vim.schedule(function()
      PackUtils.load(P, function()
        -- =========================================================================
        -- 折叠虚拟文本自定义处理器
        -- 在折叠行末尾显示：第一行内容 + 折叠行数（如 " 󰁂 12 "）
        -- =========================================================================
        local handler = function(virtText, lnum, endLnum, width, truncate)
          local newVirtText = {}

          -- 构造后缀：显示折叠的行数（例如 " 󰁂 12 "）
          local suffix = (' 󰁂 %d行'):format(endLnum - lnum)
          local sufWidth = vim.fn.strdisplaywidth(suffix)

          -- 目标宽度 = 可用文本区域宽度 - 后缀占用的宽度
          local targetWidth = width - sufWidth
          local curWidth = 0

          -- 遍历折叠首行的虚拟文本块，逐块拼接直到填满目标宽度
          for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]                           -- 文本内容
            local chunkWidth = vim.fn.strdisplaywidth(chunkText) -- 显示宽度（中文占 2 列）

            if targetWidth > curWidth + chunkWidth then
              -- 当前块完整放得下，直接追加
              table.insert(newVirtText, chunk)
            else
              -- 当前块放不下，截断到剩余宽度
              chunkText = truncate(chunkText, targetWidth - curWidth)
              local hlGroup = chunk[2] -- 保留原始高亮组
              table.insert(newVirtText, { chunkText, hlGroup })
              chunkWidth = vim.fn.strdisplaywidth(chunkText)

              -- truncate 返回的宽度可能小于目标宽度，需要用空格填充对齐
              if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
              end
              break
            end
            curWidth = curWidth + chunkWidth
          end

          -- 在末尾追加后缀（显示折叠行数），使用 MoreMsg 高亮组
          table.insert(newVirtText, { suffix, 'MoreMsg' })
          return newVirtText
        end



        -- ---------------------------------------------------------------
        -- 方案：使用 LSP 作为折叠提供者
        -- ---------------------------------------------------------------

        -- 为所有已启动的 LSP 客户端添加折叠能力声明
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.foldingRange = {
          dynamicRegistration = false, -- 不需要动态注册
          lineFoldingOnly = true,      -- 仅支持按行折叠
        }

        -- 遍历当前所有活跃的 LSP 客户端，注入折叠能力
        local language_servers = vim.lsp.get_clients()
        for _, ls in ipairs(language_servers) do
          require("lspconfig")[ls].setup({
            capabilities = capabilities,
          })
        end

        -- 初始化 ufo（使用 LSP 提供的折叠范围）
        require("ufo").setup({
          fold_virt_text_handler = handler,
          -- 展开折叠时高亮闪烁的持续时间（毫秒）
          open_fold_hl_timeout = 150,
          -- 指定文件类型中，哪些折叠类型默认关闭
          close_fold_kinds_for_ft = {
            default = { 'imports', 'comment' }, -- 默认：折叠 import 语句和注释
            json = { 'array' },                 -- JSON：折叠数组
            c = { 'comment', 'region' }         -- C：折叠注释和 #region 块
          },

          -- 光标所在行的折叠是否自动关闭
          close_fold_current_line_for_ft = {
            default = true, -- 默认：光标离开时自动折叠
            c = false       -- C 语言：不自动折叠（方便查看上下文）
          },
          -- 折叠预览浮窗配置（按 zh 预览折叠内容）
          preview = {
            win_config = {
              border = "rounded",             -- "rounded" 圆角  "single" 直角 "double" 双线
              winhighlight = 'Normal:Folded', -- 使用 Folded 高亮组
              winblend = 0                    -- 不透明
            },
            mappings = {
              scrollU = '<C-u>', -- 预览窗口中向上滚动
              scrollD = '<C-e>', -- 预览窗口中向下滚动
              jumpTop = '[',     -- 跳到预览顶部
              jumpBot = ']'      -- 跳到预览底部
            }
          },
        })
        -- ---------------------------------------------------------------
        -- 折叠快捷键
        -- ---------------------------------------------------------------
        local ufo = require("ufo")
        -- 全局折叠操作
        vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "展开所有折叠" })
        vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "关闭所有折叠" })
        vim.keymap.set("n", "zr", ufo.openFoldsExceptKinds, { desc = "展开折叠（保留 imports/注释）" })
        vim.keymap.set("n", "zm", ufo.closeFoldsWith, { desc = "按层级折叠（v:count 控制层级）" })

        -- za 切换当前折叠
        -- zo 打开当前折叠
        -- zc 关闭当前折叠
        -- 折叠导航
        vim.keymap.set("n", "z[", ufo.goPreviousClosedFold, { desc = "上个折叠处" })
        vim.keymap.set("n", "z]", ufo.goNextClosedFold, { desc = "下个折叠处" })
        vim.keymap.set("n", "z{", ufo.goPreviousStartFold, { desc = "上个折叠起始" })
        -- 预览折叠内容（浮窗显示）
        vim.keymap.set("n", "zh", function()
          local winid = ufo.peekFoldedLinesUnderCursor()
          -- 如果光标下没有折叠，回退到 LSP 悬停文档
          if not winid then
            vim.lsp.buf.hover()
          end
        end, { desc = "预览折叠内容 / 悬停文档" })
        -- 折叠当前函数（利用 treesitter 精准定位函数范围后折叠）
        vim.keymap.set("n", "zf", function()
          -- 获取当前光标位置的 treesitter 节点
          local node = vim.treesitter.get_node()
          if not node then
            vim.notify("无 Treesitter 节点", vim.log.levels.WARN)
            return
          end
          -- 向上查找最近的函数节点
          while node do
            local type = node:type()
            if type == "function_definition"      -- Python
                or type == "function_declaration" -- C/JS/Go
                or type == "function_item"        -- Rust
                or type == "method_definition"    -- JS/TS class 方法
                or type == "method_declaration"   -- Go
                or type == "function"             -- Lua
                or type == "local_function"       -- Lua local function
            then
              break
            end
            node = node:parent()
          end
          if not node then
            vim.notify("未找到函数节点", vim.log.levels.WARN)
            return
          end
          -- 获取函数起止行号并执行折叠
          local start_row = node:start()
          local end_row = node:end_()
          -- 移动光标到函数起始行，执行按行数折叠
          vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
          vim.cmd(start_row + 1 .. "," .. end_row + 1 .. "fold")
        end, { desc = "折叠当前函数" })
        -- 折叠当前代码块（if/for/while 等）
        vim.keymap.set("n", "zb", function()
          local node = vim.treesitter.get_node()
          if not node then
            vim.notify("无 Treesitter 节点", vim.log.levels.WARN)
            return
          end
          while node do
            local type = node:type()
            if type == "if_statement"
                or type == "for_statement"
                or type == "while_statement"
                or type == "do_statement"
                or type == "switch_statement"
                or type == "try_statement"
                or type == "with_statement"  -- Python
                or type == "match_statement" -- Python 3.10+
            then
              break
            end
            node = node:parent()
          end
          if not node then
            vim.notify("未找到代码块节点", vim.log.levels.WARN)
            return
          end
          local start_row = node:start()
          local end_row = node:end_()
          vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
          vim.cmd(start_row + 1 .. "," .. end_row + 1 .. "fold")
        end, { desc = "折叠当前代码块" })
        -- 折叠所有函数（保留顶层结构可见）
        vim.keymap.set("n", "zF", function()
          -- closeFoldsWith(1) = 折叠到第 1 层，通常刚好折叠所有函数体
          ufo.closeFoldsWith(1)
        end, { desc = "折叠所有函数（保留顶层）" })
      end)
    end)
  end,
})

----------------------
-- 快捷键配置 --
----------------------
vim.g.mapleader = " "      -- 全局 leader 键设为空格
vim.g.maplocalleader = " " -- 局部 leader 键

-- ============================================================================
-- 通用快捷键映射（不依赖特定插件）
-- ============================================================================
local map = vim.keymap.set

-- 退出插入模式
map("i", "jk", "<ESC>", { desc = "退出插入" })

-- 屏幕行移动（兼容 wrap 关闭的情况）
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "向下（屏幕行）" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "向上（屏幕行）" })

-- 移动行（Alt + j/k）
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "向下移动行" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "向上移动行" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "向下移动行（插入）" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "向上移动行（插入）" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "向下移动选中行" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "向上移动选中行" })

-- Esc 清除搜索高亮
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Esc 并清除搜索高亮" })

-- 搜索导航优化
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "下一个搜索结果" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "上一个搜索结果" })

-- 快速保存
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "保存文件" })

-- 关键字帮助（恢复默认 K）
map("n", "<leader>cK", "<cmd>norm! K<cr>", { desc = "关键字帮助" })

-- 缩进保持选中
map("x", "<", "<gv")
map("x", ">", ">gv")


-- 退出所有
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "退出所有" })

-- 窗口导航与拆分
map("n", "<C-h>", "<C-w>h", { desc = "左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "下方窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "上方窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "右侧窗口" })

map("n", "<leader>w-", "<C-W>s", { desc = "水平拆分", remap = true })
map("n", "<leader>w|", "<C-W>v", { desc = "垂直拆分", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "关闭窗口", remap = true })
map("n", "<leader>ww", "<C-w>w", { desc = "切换窗口焦点" })

-- 智能选择
local function smart_select(ts_method, lsp_dir)
  return function()
    -- 非普通缓冲区（Quickfix、帮助、终端等）恢复回车原本功能
    if lsp_dir == 1 and vim.bo.buftype ~= "" then
      local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
      vim.api.nvim_feedkeys(cr, "n", false)
      return
    end

    -- 优先使用 Treesitter 节点选择
    if vim.treesitter.get_parser(nil, nil, { error = false }) then
      require("vim.treesitter._select")[ts_method](vim.v.count1)
      -- 回退到 LSP（如果支持）
    elseif vim.lsp.buf.selection_range then
      vim.lsp.buf.selection_range(lsp_dir * vim.v.count1)
    else
      vim.notify("无可用的选区扩展方式", vim.log.levels.WARN)
    end
  end
end

-- 扩大范围（回车键）：向上寻找父节点
map({ "x", "o", "n" }, "<CR>", smart_select("select_parent", 1), { desc = "扩大 Treesitter/LSP 范围" })
-- 缩小范围（退格键）：向下寻找子节点
map({ "x", "o" }, "<BS>", smart_select("select_child", -1), { desc = "缩小 Treesitter/LSP 范围" })

map({ "i", "n" }, "<C-a>", "<Cmd>normal! ggVG<CR>", { silent = true, desc = "全选操作" })
-- ============================================================================
-- 批量替换
-- ============================================================================

--- 设置搜索高亮
local function highlight_search(pattern)
  vim.fn.setreg('/', pattern)
  vim.opt.hlsearch = true
  vim.cmd("redraw")
end

--- 清除搜索高亮
local function clear_highlight()
  vim.opt.hlsearch = false
end

--- 替换当前目录及子目录下所有文件内容
local function search_and_replace()
  local search_text = vim.fn.input("搜索内容: ")
  if search_text == "" then return end

  local vim_search = vim.fn.escape(search_text, '/\\.*[]^$~')
  highlight_search(vim_search)

  local ok_input, replace_text = pcall(vim.fn.input, "替换为: ")
  if not ok_input then
    clear_highlight()
    return
  end

  if vim.fn.has("win32") == 1 then
    -- Windows：使用 Neovim 内置 :vimgrep + :cfdo
    local vim_replace = vim.fn.escape(replace_text, '/\\&~')
    local ok = pcall(vim.cmd, 'silent vimgrep /' .. vim_search .. '/j **/*')
    if not ok then
      vim.notify("未找到匹配项", vim.log.levels.WARN)
      clear_highlight()
      return
    end
    vim.cmd('cfdo %s/' .. vim_search .. '/' .. vim_replace .. '/ge | update')
    print("\n✅ 已替换工作目录下所有匹配项")
  else
    -- Linux：利用已配置的 rg 代替 grep，速度更快
    local sed_search = vim.fn.escape(search_text, '/.*[]^$\\&~')
    local sed_replace = vim.fn.escape(replace_text, '/\\&~')
    local rg_arg = vim.fn.shellescape(search_text)
    local sed_arg = vim.fn.shellescape('s/' .. sed_search .. '/' .. sed_replace .. '/g')
    -- rg --files-with-matches -F：固定字符串匹配，仅输出文件名
    vim.cmd('!rg --files-with-matches -F ' .. rg_arg .. ' ./ | xargs sed -i ' .. sed_arg)
    vim.cmd("checktime")
    print("\n✅ 已替换工作目录下所有匹配项")
  end

  clear_highlight()
end

--- 替换当前文件内容
--- 直接填充命令行 :%s/，利用 inccommand = "nosplit" 实时预览替换效果
local function search_and_replace_current_file()
  -- feedkeys 填充命令行，用户可以实时看到替换预览
  -- 光标停在 替换内容/ 的位置，用户输入替换文本后按回车执行
  local keys = vim.api.nvim_replace_termcodes(":%s//g<Left><Left>", true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

map("n", "<leader>sa", search_and_replace, { desc = "替换工作目录下所有文件内容" })
map("n", "<leader>sr", search_and_replace_current_file, { desc = "替换当前文件内容" })

map("n", "<leader>uu",function ()
  vim.cmd([[packadd nvim.undotree]])
  require('undotree').open()
end , { desc = "撤销树" })

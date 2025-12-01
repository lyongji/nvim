vim.pack.add({
  -- { src = 'https://github.com/nvim-mini/mini.pick' },   -- 文件/缓冲区选择器
  { src = 'https://github.com/nvim-mini/mini.files' }, -- 文件浏览器
})

----------------------
-- 插件配置 --
----------------------

-- mini.files 文件浏览器配置
require('mini.files').setup({
  windows = {
    preview = true, -- 打开预览窗口
  },
})

-- require('mini.pick').setup()

----------------------
-- 快捷键配置 --
----------------------
vim.keymap.set('n', '<leader>e', ':lua MiniFiles.open()<CR>', { desc = '打开文件浏览器' })
-- 打开 mini.files（当前文件所在目录）
vim.keymap.set("n", "<leader>e", function()
  require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
end, { desc = "打开文件浏览器（文件所在目录）" })

-- 打开 mini.files（当前工作目录）
vim.keymap.set("n", "<leader>E", function()
  require("mini.files").open(vim.uv.cwd(), true)
end, { desc = "打开文件浏览器（工作目录）" })

-- 控制是否显示隐藏文件（以点开头的文件）的标志
local show_dotfiles = true

-- 显示所有文件的过滤器函数（不过滤任何文件）
local filter_show = function(fs_entry)
  return true
end

-- 隐藏以点开头的文件的过滤器函数
local filter_hide = function(fs_entry)
  return not vim.startswith(fs_entry.name, ".")
end

-- 切换隐藏文件显示状态的函数
local toggle_dotfiles = function()
  -- 切换显示/隐藏标志
  show_dotfiles = not show_dotfiles
  -- 根据标志选择相应的过滤器
  local new_filter = show_dotfiles and filter_show or filter_hide
  -- 刷新 mini.files 内容应用新过滤器
  require("mini.files").refresh({ content = { filter = new_filter } })
end

-- 创建在分割窗口中打开文件的快捷键映射函数
-- @param buf_id: 缓冲区ID
-- @param lhs: 快捷键（左手键）
-- @param direction: 分割方向（"horizontal" 或 "vertical"）
-- @param close_on_file: 打开文件后是否关闭文件浏览器
local map_split = function(buf_id, lhs, direction, close_on_file)
  local rhs = function()
    local new_target_window
    -- 获取当前文件浏览器的目标窗口
    local cur_target_window = require("mini.files").get_explorer_state().target_window

    if cur_target_window ~= nil then
      -- 在目标窗口中执行分割命令
      vim.api.nvim_win_call(cur_target_window, function()
        vim.cmd("belowright " .. direction .. " split")
        new_target_window = vim.api.nvim_get_current_win()
      end)

      -- 设置新的目标窗口并进入文件
      require("mini.files").set_target_window(new_target_window)
      require("mini.files").go_in({ close_on_file = close_on_file })
    end
  end

  -- 构建快捷键描述
  local desc = "在 " .. direction .. " 分割窗口中打开"
  if close_on_file then
    desc = desc .. "并关闭文件浏览器"
  end

  -- 设置缓冲区内的快捷键映射
  vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
end

-- 设置当前工作目录为当前选中文件所在目录的函数
local files_set_cwd = function()
  -- 获取当前选中的文件系统条目路径
  local cur_entry_path = MiniFiles.get_fs_entry().path
  -- 提取目录部分
  local cur_directory = vim.fs.dirname(cur_entry_path)

  if cur_directory ~= nil then
    -- 改变当前工作目录
    vim.fn.chdir(cur_directory)
  end
end

-- 当 mini.files 缓冲区创建时执行的自动命令
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate", -- 监听 MiniFilesBufferCreate 事件
  callback = function(args)
    local buf_id = args.data.buf_id  -- 获取新创建的缓冲区ID

    -- 设置切换隐藏文件的快捷键
    vim.keymap.set(
      "n",
      "g.", -- 使用配置中的键位或默认值
      toggle_dotfiles,
      { buffer = buf_id, desc = "切换隐藏文件显示" }
    )

    -- 设置改变工作目录的快捷键
    vim.keymap.set(
      "n",
      "gc",
      files_set_cwd,
      { buffer = args.data.buf_id, desc = "设置当前工作目录" }
    )

    -- 设置四种分割窗口打开的快捷键映射：
    -- 1. 水平分割打开（不关闭文件浏览器）
    map_split(buf_id, "<C-w>s", "horizontal", false)
    -- 2. 垂直分割打开（不关闭文件浏览器）
    map_split(buf_id, "<C-w>v", "vertical", false)
    -- 3. 水平分割打开并关闭文件浏览器
    map_split(buf_id, "<C-w>S", "horizontal", true)
    -- 4. 垂直分割打开并关闭文件浏览器
    map_split(buf_id, "<C-w>V", "vertical", true)
  end,
})

-- 当 mini.files 中重命名文件时执行的自动命令
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesActionRename", -- 监听 MiniFilesActionRename 事件
  callback = function(event)
    -- 调用 Snacks.rename 模块的 on_rename_file 函数处理重命名后的操作
    Snacks.rename.on_rename_file(event.data.from, event.data.to)
  end,
})

-- vim.keymap.set('n', '<leader>f', ':Pick files<CR>', { desc = '打开文件选择器' })
-- vim.keymap.set('n', '<leader>h', ':Pick help<CR>', { desc = '打开帮助选择器' })
-- vim.keymap.set('n', '<leader>b', ':Pick buffers<CR>', { desc = '打开缓冲区选择器' })

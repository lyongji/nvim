-- 本地插件：拼音补全
vim.opt.rtp:prepend("E:/code/pinyin_cmp")
vim.schedule(function()
  local ok, mod = pcall(require, 'cmp_pinyin')
  if not ok then
    vim.notify('[cmp_pinyin] 模块加载失败: ' .. tostring(mod), vim.log.levels.ERROR)
    return
  end
  mod.setup({ notation = { '简拼', '全拼' } })
  vim.notify('[cmp_pinyin] 已启动, CLI: ' .. mod.config.cli_path, vim.log.levels.INFO)
end)

-- nvim 的原生功能实现
-- require('lua.tool.缩进线').setup({
--   char = '┊',
--   scope_char = '│',
--   exclude_ft = { 'help', 'dashboard', 'lazy', 'mason' },
-- })
-- ===
-- === 终端
-- ===
local term = require("tool.terminal")
-- 创建用户命令
vim.api.nvim_create_user_command('TermToggle', function()
  term.toggle_term()
end, { desc = '打开/关闭浮动终端' })

vim.api.nvim_create_user_command('TermPos', function()
  term.toggle_term('pos')
end, { desc = '切换终端布局位置' })


-- 绑定快捷键到命令
vim.keymap.set({ 'n', 't' }, '<A-d>', '<cmd>TermToggle<CR>')
vim.keymap.set({ 'n', 't' }, '<A-s>', '<cmd>TermPos<CR>')
-- 终端内快捷键
vim.keymap.set('t', '<C-q>', '<C-\\><C-n>', { desc = '退出终端插入模式' })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "退出终端插入模式" })

-- ===
-- === 快速修复列表
-- ===
local qf = require('tool.快速修复列表')
local map = vim.keymap.set
  -- 导航      j/k  ↑/↓       上下移动
  --           C-d/C-u         翻页（±10）
  --           gg / G          首项 / 末项
  --
  -- 打开      Enter / o       跳转并关闭
  --           s               水平分屏打开
  --           v               垂直分屏打开
  --
  -- 预览      p               预览（不关闭）
  --           Tab / S-Tab     逐项预览
  --
  -- 编辑      dd              删除当前条目
  --           C               清空整个列表
  --
  -- 其他      L               右侧 ↔ 底部
  --           R               刷新列表
  --           q / Esc         关闭
-- ── 切换列表 ──
map('n', '<leader>xq', qf.toggle_qf,                            { desc = '快速修复列表' })
map('n', '<leader>xl', qf.toggle_loc,                            { desc = '位置列表' })
map('n', '<leader>xL', qf.switch_layout,                         { desc = '切换列表布局' })

-- ── 导航 ──
map('n', '[q', function() qf.navigate('qf',  'prev') end,        { desc = '上个快速修复项' })
map('n', ']q', function() qf.navigate('qf',  'next') end,        { desc = '下个快速修复项' })
map('n', '[l', function() qf.navigate('loc', 'prev') end,        { desc = '上个位置列表项' })
map('n', ']l', function() qf.navigate('loc', 'next') end,        { desc = '下个位置列表项' })

-- ── 添加当前位置 ──
map('n', '<leader>xa', qf.add_pos_qf,                            { desc = '标记到快速修复' })
map('n', '<leader>xA', qf.add_pos_loc,                           { desc = '标记到位置列表' })

-- ── 清空 ──
map('n', '<leader>xc', qf.clear_qf,                              { desc = '清空快速修复' })
map('n', '<leader>xC', qf.clear_loc,                              { desc = '清空位置列表' })

-- ── LSP 诊断 ──
map('n', '<leader>xd', function() qf.diag_qf('buffer') end,      { desc = '当前文件诊断' })
map('n', '<leader>xD', function() qf.diag_qf('all') end,         { desc = '工作区诊断' })



local sticky = require('tool.便签')

-- 快捷键设置 (可自定义)
vim.keymap.set('n', '<A-b>',function() sticky.toggle() end , { desc = '开关便签' })
vim.keymap.set('n', '<A-B>',function()  sticky.switch() end , { desc = '便签切换' })


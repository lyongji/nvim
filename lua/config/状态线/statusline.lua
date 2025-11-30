-- 引入组件模块
local components = require 'config.状态线.组件'

-- 设置命令行高度为0（将命令显示在状态线中）
vim.o.cmdheight = 0

-- 返回状态线配置表
return { -- statusline
  -- ========== 左侧区域 ==========
  
  -- 模式显示组件，右侧添加1个空格
  components.RightPadding(components.Mode, 1),
  
  -- 文件名块组件，右侧添加1个空格
  components.RightPadding(components.FileNameBlock, 1),
  
  -- Git 状态组件，右侧添加1个空格
  components.RightPadding(components.Git, 1),
  
  -- 诊断信息组件，右侧添加1个空格
  components.RightPadding(components.Diagnostics, 1),
  
  -- Overseer 任务组件，右侧添加1个空格
  components.RightPadding(components.Overseer, 1),
  
  -- 搜索匹配统计组件，右侧不添加空格
  components.RightPadding(components.SearchOccurrence, 0),
  
  -- ========== 中间填充区域 ==========
  
  -- 填充组件（将左右内容分开）
  components.Fill,
  
  -- 宏录制显示组件（居中显示）
  components.MacroRecording,
  
  -- 填充组件（确保右侧内容靠右对齐）
  components.Fill,
  
  -- ========== 右侧区域 ==========
  
  -- 命令显示组件
  components.RightPadding(components.ShowCmd),
  
  -- LSP 活动客户端组件（已注释）
  -- components.RightPadding(components.LSPActive),
  
  -- LSP 进度组件，右侧添加1个空格
  components.RightPadding(components.LspProgress, 1),
  
  -- 格式化工具组件，右侧添加1个空格
  components.RightPadding(components.Formatters, 1),
  
  -- 简单指示器组件（已注释）
  -- components.RightPadding(components.SimpleIndicator),
  
  -- 文件类型组件，右侧不添加空格
  components.RightPadding(components.FileType, 0),
  
  -- 标尺组件（显示行列信息和百分比）
  components.Ruler,
  
  -- 滚动条组件（已注释）
  -- components.ScrollBar,
}
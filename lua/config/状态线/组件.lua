-- 引入必要的模块
local palette = require('catppuccin.palettes').get_palette 'mocha'  -- 获取 catppuccin mocha 主题的调色板
local utils = require 'heirline.utils'  -- Heirline 工具函数
local conditions = require 'heirline.conditions'  -- Heirline 条件判断
local icons = require 'config.icons'  -- 自定义图标配置

-- 定义颜色变量，从高亮组获取颜色
local colors = {
    diag_warn = utils.get_highlight('DiagnosticWarn').fg,    -- 诊断警告颜色
    diag_error = utils.get_highlight('DiagnosticError').fg,  -- 诊断错误颜色
    diag_hint = utils.get_highlight('DiagnosticHint').fg,    -- 诊断提示颜色
    diag_info = utils.get_highlight('DiagnosticInfo').fg,    -- 诊断信息颜色
    git_del = utils.get_highlight('diffDeleted').fg,         -- Git 删除颜色
    git_add = utils.get_highlight('diffAdded').fg,           -- Git 添加颜色
    git_change = utils.get_highlight('diffChanged').fg,      -- Git 修改颜色
}

-- 定义暗淡颜色（用于非活动状态）
local dim_color = palette.surface1

-- Overseer 任务状态显示函数
local function OverseerTasksForStatus(st)
    return {
        condition = function(self)
            return self.tasks[st]  -- 条件：存在指定状态的任务
        end,
        provider = function(self)
            -- 提供器：显示任务数量和图标
            return string.format('%s%d', self.symbols[st], #self.tasks[st])
        end,
        hl = function(_)
            -- 高亮：根据任务状态设置颜色
            return {
                fg = utils.get_highlight(string.format('Overseer%s', st)).fg,
            }
        end,
    }
end

-- 主模块表
local M = {}

-- 基础组件 ===============================================================

-- 空格组件
M.Spacer = { provider = ' ' }

-- 填充组件（用于对齐）
M.Fill = { provider = '%=' }

-- 标尺组件（显示行列信息和百分比）
M.Ruler = {
    -- %l = 当前行号
    -- %L = 缓冲区总行数  
    -- %c = 列号
    -- %P = 窗口显示的文件百分比
    provider = '%4l,%-3c %P',
}

-- 滚动条组件
M.ScrollBar = {
    static = {
        sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' },  -- 滚动条字符
    },
    provider = function(self)
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]  -- 当前行
        local lines = vim.api.nvim_buf_line_count(0)         -- 总行数
        -- 计算滚动条位置
        local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
        return string.rep(self.sbar[i], 2)  -- 返回滚动条字符
    end,
    hl = { fg = palette.yellow, bg = palette.base },  -- 高亮设置
}

-- 间距工具函数
M.RightPadding = function(child, num_space)
    local result = {}
    
    -- 安全地处理 child 参数
    if child ~= nil then
        result.condition = child.condition
        table.insert(result, child)
    else
        -- 如果 child 为 nil，创建一个空的 condition
        result.condition = false
    end
    
    -- 添加指定数量的空格
    if num_space ~= nil then
        for _ = 1, num_space do
            table.insert(result, M.Spacer)
        end
    end
    
    return result
end

-- 模式显示组件 ===========================================================

M.Mode = {
    init = function(self)
        self.mode = vim.fn.mode(1)  -- 获取当前模式
    end,
    static = {
        -- 模式名称映射
        mode_names = {
            n = 'N普通',    -- 普通模式
            -- n = 'NORMAL',    -- 普通模式
            no = '?',
            nov = '?',
            noV = '?',
            ['no\22'] = '?',
            niI = 'i',
            niR = 'r',
            niV = 'Nv',
            nt = 'N-TERM',   -- 终端模式
            v = 'V可视',    -- 可视模式
            -- v = 'VISUAL',    -- 可视模式
            vs = 'Vs',
            V = '行可视',    -- 行可视模式
            -- V = 'V-LINE',    -- 行可视模式
            Vs = 'Vs',
            ['\22'] = '块可视',  -- 块可视模式
            -- ['\22'] = 'VBLOCK',  -- 块可视模式
            ['\22s'] = '\\',
            s = 'S选择',    -- 选择模式
            -- s = 'SELECT',    -- 选择模式
            S = '行选择',
            -- S = 'S-LINE',
            ['\19'] = '^S',
            i = 'I插入',    -- 插入模式
            -- i = 'INSERT',    -- 插入模式
            ic = 'Ic',
            ix = 'Ix',
            R = 'R替换',    -- 替换模式
            -- R = 'RPLACE',    -- 替换模式
            Rc = 'Rc',
            Rx = 'Rx',
            Rv = 'V-RPLC',
            Rvc = 'Rv',
            Rvx = 'Rv',
            c = '',
            cv = 'Ex',
            r = '...',
            rm = 'M',
            ['r?'] = '?',
            ['!'] = '!',
            t = 'TERM',      -- 终端模式
        },
        -- 模式对应的颜色
        mode_colors = {
            n = dim_color,      -- 普通模式
            nt = dim_color,     -- 终端普通模式
            i = palette.blue,   -- 插入模式
            v = palette.mauve,  -- 可视模式
            V = palette.mauve,  -- 行可视模式
            ['\22'] = palette.mauve,  -- 块可视模式
            c = palette.red,    -- 命令模式
            s = palette.pink,   -- 选择模式
            S = palette.pink,
            ['\19'] = palette.pink,
            R = palette.peach,  -- 替换模式
            r = palette.peach,
            ['!'] = palette.red,
            t = palette.blue,   -- 终端模式
        },
    },
    provider = function(self)
        return ' ' .. '%1(' .. self.mode_names[self.mode] .. '%)' .. ' ▍'
    end,
    hl = function(self)
        local mode = self.mode:sub(1, 1)  -- 获取模式首字符
        return { fg = palette.base, bg = self.mode_colors[mode], bold = true }
    end,
    -- 模式改变时更新
    update = {
        'ModeChanged',
        pattern = '*:*',
        callback = vim.schedule_wrap(function()
            pcall(vim.cmd, 'redrawstatus')  -- 重绘状态线
        end),
    },
}

-- 宏录制组件 ===========================================================

M.MacroRecording = {
    condition = conditions.is_active,  -- 条件：缓冲区活动
    init = function(self)
        self.reg_recording = vim.fn.reg_recording()  -- 获取正在录制的宏寄存器
        -- Git 状态信息
        self.status_dict = vim.b.gitsigns_status_dict or { added = 0, removed = 0, changed = 0 }
        self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
    end,
    {
        condition = function(self)
            return self.reg_recording ~= ''  -- 条件：正在录制宏
        end,
        {
            provider = '󰻃 ',  -- 宏录制图标
            hl = { fg = palette.maroon },
        },
        {
            provider = function(self)
                return self.reg_recording  -- 显示宏寄存器名称
            end,
            hl = { fg = palette.maroon, italic = false, bold = true },
        },
        hl = { fg = palette.text, bg = palette.base },
    },
    update = { 'RecordingEnter', 'RecordingLeave' },  -- 录制开始/结束时更新
}

-- 格式化工具组件 =======================================================

M.Formatters = {
    condition = function(self)
        -- 条件：conform.nvim 可用
        local ok, conform = pcall(require, 'conform')
        self.conform = conform
        return ok
    end,
    update = { 'BufEnter' },  -- 缓冲区进入时更新
    provider = function(self)
        -- 获取当前文件类型的格式化工具
        local ft_entry = self.conform.formatters_by_ft[vim.bo.filetype]
        local ft_formatters
        if type(ft_entry) == 'function' then
            ft_formatters = ft_entry()
        else
            ft_formatters = ft_entry
        end
        return ft_formatters and table.concat(ft_formatters, ',') or ''
    end,
    hl = { fg = dim_color, bold = false },
}

-- LSP 活动组件 ========================================================

M.LSPActive = {
    condition = conditions.lsp_attached,  -- 条件：有 LSP 附加
    update = { 'LspAttach', 'LspDetach' },  -- LSP 附加/分离时更新
    provider = function()
        local names = {}
        -- 获取当前缓冲区的所有 LSP 客户端名称
        ---@diagnostic disable-next-line: deprecated
        for _, server in pairs(vim.lsp.get_clients { bufnr = 0 }) do
            table.insert(names, server.name)
        end
        return table.concat(names, ',')  -- 返回逗号分隔的 LSP 名称
    end,
    hl = { fg = dim_color, bold = false },
}

-- 文件类型组件 ========================================================

M.FileType = {
    provider = function()
        return vim.bo.filetype  -- 返回文件类型
    end,
    hl = { fg = utils.get_highlight('Type').fg, bold = true },
}

-- Codeium 状态组件 ====================================================

M.CodeiumStatus = {
    init = function(self)
        -- 检查 Codeium 是否可用
        self.codeium_exist = vim.fn.exists '*codeium#GetStatusString' == 1
        self.codeium_status = self.codeium_exist and vim.fn['codeium#GetStatusString']() or nil
    end,
    provider = function(self)
        if not self.codeium_exist then
            return ''
        end
        -- 根据 Codeium 状态返回不同图标
        if self.codeium_status == ' ON' then
            return '󰚩 '  -- Codeium 开启
        elseif self.codeium_status == ' OFF' then
            return '󱚡 '  -- Codeium 关闭
        else
            return '󱚝 '  -- Codeium 未知状态
        end
    end,
    hl = function(self)
        -- 根据状态设置颜色
        if self.codeium_status == ' ON' then
            return { fg = palette.green }   -- 开启：绿色
        elseif self.codeium_status == ' OFF' then
            return { fg = palette.gray }    -- 关闭：灰色
        else
            return { fg = palette.maroon }  -- 未知：栗色
        end
    end,
}

-- Git 组件 ============================================================

M.Git = {
    condition = conditions.is_git_repo,  -- 条件：在 Git 仓库中

    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict  -- Git 状态字典
        self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
    end,

    hl = function(self)
        return { fg = self.has_changes and palette.maroon or dim_color }
    end,

    { -- Git 分支名称
        provider = function(self)
            if self.has_changes then
                return '󰘬 ' .. self.status_dict.head .. '*'  -- 有更改时显示星号
            else
                return '󰘬 ' .. self.status_dict.head
            end
        end,
    },
}

-- 诊断信息组件 ========================================================

M.Diagnostics = {
    condition = conditions.has_diagnostics,  -- 条件：有诊断信息
    static = {
        -- 诊断图标
        error_icon = icons.diagnostics.Error .. ' ',
        warn_icon = icons.diagnostics.Warn .. ' ',
        info_icon = icons.diagnostics.Info .. ' ',
        hint_icon = icons.diagnostics.Hint .. ' ',
    },

    init = function(self)
        -- 获取各种严重程度的诊断数量
        self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,

    update = { 'DiagnosticChanged', 'BufEnter' },  -- 诊断改变或缓冲区进入时更新

    -- 错误诊断
    {
        provider = function(self)
            return self.errors > 0 and (self.error_icon .. self.errors .. ' ')
        end,
        hl = { fg = colors.diag_error },
    },
    -- 警告诊断
    {
        provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. self.warnings .. ' ')
        end,
        hl = { fg = colors.diag_warn },
    },
    -- 信息诊断
    {
        provider = function(self)
            return self.info > 0 and (self.info_icon .. self.info .. ' ')
        end,
        hl = { fg = colors.diag_info },
    },
    -- 提示诊断
    {
        provider = function(self)
            return self.hints > 0 and (self.hint_icon .. self.hints)
        end,
        hl = { fg = colors.diag_hint },
    },
}

-- 文件图标组件 ========================================================

M.FileIcon = {
    condition = function(self)
        return vim.fn.fnamemodify(self.filename, ':.') ~= ''  -- 条件：文件名不为空
    end,
    init = function(self)
        self.is_modified = vim.api.nvim_get_option_value('modified', { buf = self.bufnr })  -- 文件是否修改
        local filename = self.filename
        local extension = vim.fn.fnamemodify(filename, ':e')  -- 文件扩展名
        -- 获取文件图标（需要 MiniIcons 插件）
        local icon, hl, _ = MiniIcons.get('file', 'file.' .. extension)
        local bt = vim.api.nvim_get_option_value('buftype', { buf = self.bufnr }) or nil
        if bt and bt == 'terminal' then
            icon = ''  -- 终端图标
        end
        self.icon = icon
        self.icon_color = string.format('#%06x', vim.api.nvim_get_hl(0, { name = hl })['fg'])  -- 图标颜色
    end,
    provider = function(self)
        return self.icon and (self.icon .. ' ')  -- 返回图标
    end,
    hl = function(self)
        return { fg = self.is_modified and self.icon_color or dim_color }  -- 修改时使用图标颜色
    end,
}

-- 文件名组件 ==========================================================

M.FileName = {
    init = function(self)
        self.is_modified = vim.api.nvim_get_option_value('modified', { buf = self.bufnr })  -- 文件是否修改
        local filename = self.filename
        local extension = vim.fn.fnamemodify(filename, ':e')
        local _, hl, _ = MiniIcons.get('file', 'file.' .. extension)
        self.icon_color = string.format('#%06x', vim.api.nvim_get_hl(0, { name = hl })['fg'])
    end,
    provider = function(self)
        -- 获取文件名，如果为空则显示文件类型
        local filename = self.filename
        filename = filename == '' and vim.bo.filetype or vim.fn.fnamemodify(filename, ':t')
        return '' .. filename .. ''
    end,
    hl = function(self)
        return {
            fg = self.is_modified and self.icon_color or dim_color,  -- 修改时使用特殊颜色
            italic = self.is_modified,  -- 修改时使用斜体
        }
    end,
}

-- 文件路径组件 ========================================================

M.FilePath = {
    provider = function(self)
        -- 获取相对当前目录的文件路径
        local filename = vim.fn.fnamemodify(self.filename, ':.')
        if filename == '' then
            return vim.bo.filetype ~= '' and vim.bo.filetype or vim.bo.buftype
        end
        return filename
    end,
    hl = function(self)
        return {
            fg = self.is_active and palette.text or palette.subtext0,  -- 活动状态使用主文本颜色
            bold = self.is_active or self.is_visible,
            italic = self.is_active,
        }
    end,
}

-- 文件标志组件 ========================================================

M.FileFlags = {
    {
        init = function(self)
            local filename = self.filename
            local extension = vim.fn.fnamemodify(filename, ':e')
            local _, hl, _ = MiniIcons.get('file', 'file.' .. extension)
            self.icon_color = string.format('#%06x', vim.api.nvim_get_hl(0, { name = hl })['fg'])
        end,
        condition = function(self)
            -- 条件：文件已修改且不在忽略的文件类型中
            local ignored_filetypes = {
                'dap-repl',
            }
            local result = vim.fn.fnamemodify(self.filename, ':.') ~= '' and
            vim.api.nvim_get_option_value('modified', { buf = self.bufnr })
            local ft = vim.api.nvim_get_option_value('buftype', { buf = self.bufnr })
            if vim.tbl_contains(ignored_filetypes, ft) then
                result = false
            end
            return result
        end,
        provider = ' [+]',  -- 修改标志
        hl = function(self)
            return { fg = self.icon_color, bold = self.is_active }
        end,
    },
    {
        condition = function(self)
            -- 条件：文件不可修改或只读
            return not vim.api.nvim_get_option_value('modifiable', { buf = self.bufnr }) or
            vim.api.nvim_get_option_value('readonly', { buf = self.bufnr })
        end,
        provider = function(self)
            if vim.api.nvim_get_option_value('buftype', { buf = self.bufnr }) == 'terminal' then
                return ''
            else
                return ' '  -- 只读锁图标
            end
        end,
        hl = { fg = palette.text },
    },
}

-- Overseer 任务组件 ===================================================

M.Overseer = {
    condition = function()
        return package.loaded.overseer  -- 条件：overseer 插件已加载
    end,
    init = function(self)
        -- 获取按状态分组的任务
        local tasks = require('overseer.task_list').list_tasks { unique = true }
        local tasks_by_status = require('overseer.util').tbl_group_by(tasks, 'status')
        self.tasks = tasks_by_status
    end,
    static = {
        symbols = {
            ['CANCELED'] = ' 󰩹 ',  -- 取消任务图标
            ['FAILURE'] = '  ',   -- 失败任务图标
            ['SUCCESS'] = '  ',   -- 成功任务图标
            ['RUNNING'] = '  ',   -- 运行中任务图标
        },
    },
    -- 显示各种状态的任务数量
    M.RightPadding(OverseerTasksForStatus 'CANCELED'),
    M.RightPadding(OverseerTasksForStatus 'RUNNING'),
    M.RightPadding(OverseerTasksForStatus 'SUCCESS'),
    M.RightPadding(OverseerTasksForStatus 'FAILURE'),
}

-- 文件名块组件（组合组件）============================================

M.FileNameBlock = {
    init = function(self)
        local bufnr = self.bufnr and self.bufnr or 0
        self.filename = vim.api.nvim_buf_get_name(bufnr)  -- 获取缓冲区文件名
    end,
    hl = { fg = palette.text },
    M.FileIcon,    -- 文件图标
    M.FileName,    -- 文件名
    M.FileFlags,   -- 文件标志
}

-- 文件路径块组件 =====================================================

M.FilePathBlock = {
    init = function(self)
        local bufnr = self.bufnr and self.bufnr or 0
        self.filename = vim.api.nvim_buf_get_name(bufnr)
    end,
    hl = { fg = palette.text },
    M.FileIcon,    -- 文件图标
    M.FileName,    -- 文件名
    M.FileFlags,   -- 文件标志
}

-- 标签页文件名块组件（带点击事件）====================================

M.TablineFileNameBlock = vim.tbl_extend('force', M.FileNameBlock, {
    on_click = {
        callback = function(_, minwid, _, button)
            if button == 'm' then -- 鼠标中键点击关闭缓冲区
                vim.schedule(function()
                    vim.api.nvim_buf_delete(minwid, { force = false })
                end)
            else
                vim.api.nvim_win_set_buf(0, minwid)  -- 切换到该缓冲区
            end
        end,
        minwid = function(self)
            return self.bufnr  -- 返回缓冲区号
        end,
        name = 'heirline_tabline_buffer_callback',
    },
})

-- 命令显示组件 =======================================================

vim.opt.showcmdloc = 'statusline'  -- 在状态线显示命令
M.ShowCmd = {
    condition = function()
        return vim.o.cmdheight == 0  -- 条件：命令行为0
    end,
    provider = '%3.5(%S%)',  -- 显示命令
}

-- 搜索出现次数组件 ===================================================

M.SearchOccurrence = {
    condition = function()
        return vim.v.hlsearch == 1  -- 条件：有高亮搜索
    end,
    hl = { fg = palette.sky },
    provider = function()
        local sinfo = vim.fn.searchcount { maxcount = 0 }  -- 获取搜索统计
        local search_stat = sinfo.incomplete > 0 and ' [?/?]' or
        sinfo.total > 0 and (' [%s/%s]'):format(sinfo.current, sinfo.total) or ''
        return search_stat  -- 返回搜索统计信息
    end,
}

-- 简单指示器组件 =====================================================

M.SimpleIndicator = {
    condition = function()
        return vim.g.simple_indicator_on  -- 条件：全局变量开启
    end,
    hl = { fg = palette.sky },
    provider = '',  -- 简单指示器图标
}

-- LSP 进度组件 =======================================================

M.LSPProgress = {
    provider = function()
        return require('lsp-progress').progress {
            format = function(messages)
                local active_clients = vim.lsp.get_clients()  -- 获取活动 LSP 客户端
                local client_count = #active_clients

                if #messages > 0 then
                    return table.concat(messages, ' ')  -- 有进度消息时显示消息
                end

                if client_count <= 0 then
                    return client_count  -- 无客户端时显示数量
                else
                    -- 显示所有客户端名称
                    local name_set = {}
                    local client_names = {}

                    for _, client in ipairs(active_clients) do
                        if client and client.name ~= '' and not name_set[client.name] then
                            name_set[client.name] = true
                            table.insert(client_names, '[' .. client.name .. ']')
                        end
                    end

                    return table.concat(client_names, ' ')
                end
            end,
        }
    end,
    update = {
        'User',
        pattern = 'LspProgressStatusUpdated',  -- LSP 进度更新时触发
        callback = vim.schedule_wrap(function()
            vim.cmd 'redrawstatus'  -- 重绘状态线
        end),
    },
    hl = { fg = dim_color, bold = false },
}

-- 返回模块
return M
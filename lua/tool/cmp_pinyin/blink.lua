local cmp_pinyin = require('tool.cmp_pinyin')

local function dbg(msg) end

--- 提取光标前的拼音查询词（仅 ASCII 字母）
local function get_query()
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.')

    local end_pos = col - 1
    local start = end_pos
    while start > 0 and line:sub(start, start):match('[%a]') do
        start = start - 1
    end
    if start < end_pos then
        return line:sub(start + 1, end_pos)
    end
    return ''
end

-- LSP CompletionItemKind 枚举值，带回退
local kind_text = 1
local kind_keyword = 14
local ok, types = pcall(require, 'blink.cmp.types')
if ok and types.CompletionItemKind then
    kind_text = types.CompletionItemKind.Text
    kind_keyword = types.CompletionItemKind.Keyword or 14
end

-- LSP SymbolKind → blink CompletionItemKind 映射
local lsp_kind_to_cmp = {
    [5] = types and types.CompletionItemKind and types.CompletionItemKind.Class or 7,
    [6] = types and types.CompletionItemKind and types.CompletionItemKind.Method or 2,
    [9] = types and types.CompletionItemKind and types.CompletionItemKind.Constructor or 4,
    [12] = types and types.CompletionItemKind and types.CompletionItemKind.Function or 3,
    [13] = types and types.CompletionItemKind and types.CompletionItemKind.Variable or 6,
    [14] = types and types.CompletionItemKind and types.CompletionItemKind.Constant or 21,
    [22] = types and types.CompletionItemKind and types.CompletionItemKind.EnumMember or 20,
    [23] = types and types.CompletionItemKind and types.CompletionItemKind.Struct or 22,
}

local callable_kinds = { [6] = true, [9] = true, [12] = true }

local M = {}

function M.new(opts)
    return setmetatable(opts or {}, { __index = M })
end

function M:get_completions(ctx, callback)
    local query = get_query()

    if #query < (cmp_pinyin.config.min_query_len or 2) then
        return callback({
            items = {},
            is_incomplete_forward = true,
            is_incomplete_backward = true,
        })
    end

    local bufnr = ctx.bufnr or vim.api.nvim_get_current_buf()

    local context = cmp_pinyin.get_cursor_context()
    local candidates
    if context == 'code' then
        candidates = cmp_pinyin.collect_candidates(bufnr, { mode = 'code' })
    elseif context == 'comment' or context == 'string' then
        candidates = cmp_pinyin.collect_candidates(bufnr, { mode = 'text' })
    else
        candidates = cmp_pinyin.collect_candidates(bufnr, { mode = 'all' })
    end

    if #candidates == 0 then
        return callback({
            items = {},
            is_incomplete_forward = true,
            is_incomplete_backward = true,
        })
    end

    local matches = cmp_pinyin.run_cli_sync(query, candidates)

    if #matches == 0 then
        return callback({
            items = {},
            is_incomplete_forward = true,
            is_incomplete_backward = true,
        })
    end

    local items = {}
    for i, m in ipairs(matches) do
        local info = cmp_pinyin.get_lsp_symbol_info(m.word, bufnr)
        local lsp_kind = info and info.kind
        local is_callable = lsp_kind and callable_kinds[lsp_kind]

        items[i] = {
            label = m.word,
            insertText = is_callable and (m.word .. '()') or m.word,
            filterText = query .. ' ' .. m.word,
            sortText = m.word,
            kind = lsp_kind and lsp_kind_to_cmp[lsp_kind]
                or (context == 'code' and kind_keyword or kind_text),
        }
    end

    callback({
        items = items,
        is_incomplete_forward = true,
        is_incomplete_backward = true,
    })
end

return M
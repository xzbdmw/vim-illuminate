local util = require("illuminate.util")
local config = require("illuminate.config")
local ref = require("illuminate.reference")

local M = {}

local HL_NAMESPACE = vim.api.nvim_create_namespace("illuminate.highlight")
local HL_K_NAMESPACE = vim.api.nvim_create_namespace("illuminate.highlightkeep")

local function kind_to_hl_group(kind)
    return kind == vim.lsp.protocol.DocumentHighlightKind.Text and "IlluminatedWordText"
        or kind == vim.lsp.protocol.DocumentHighlightKind.Read and "IlluminatedWordRead"
        or kind == vim.lsp.protocol.DocumentHighlightKind.Write and "IlluminatedWordWrite"
        or "IlluminatedWordText"
end

local function keeped_kind_to_hl_group(kind)
    return kind == vim.lsp.protocol.DocumentHighlightKind.Text and "illuminatedWordKeepText"
        or kind == vim.lsp.protocol.DocumentHighlightKind.Read and "illuminatedWordKeepRead"
        or kind == vim.lsp.protocol.DocumentHighlightKind.Write and "illuminatedWordKeepWrite"
        or "illuminatedWordKeepText"
end

--- @generic F: function
--- @param f F
--- @param ms? number
--- @return F
local function throttle(f, ms)
    ms = ms or 200
    local timer = assert(vim.loop.new_timer())
    local waiting = 0
    return function()
        if timer:is_active() then
            waiting = waiting + 1
            return
        end
        waiting = 0
        f() -- first call, execute immediately
        timer:start(ms, 0, function()
            if waiting > 1 then
                vim.schedule(f) -- only execute if there are calls waiting
            end
        end)
    end
end

local update = function()
    local api = vim.api
    local bufnr = api.nvim_get_current_buf()
    local winid = api.nvim_get_current_win()
    local success, t = pcall(require, "treesitter-context.context")
    if success then
        local context, context_lines = t.get(bufnr, winid)
        if not context or #context == 0 then
            return
        end
        if vim.w[winid].gitsigns_preview then
            return
        end
        require("treesitter-context.render").open(bufnr, winid, context, context_lines, true)
    end
end

function M.buf_highlight_references(bufnr, references)
    if config.min_count_to_highlight() > #references then
        return
    end
    local cursor_pos = util.get_cursor_pos()
    for _, reference in ipairs(references) do
        if config.under_cursor(bufnr) or not ref.is_pos_in_ref(cursor_pos, reference) then
            M.range(bufnr, reference[1], reference[2], reference[3])
        end
    end
    update()
    if _G.leapjump then
        vim.cmd("redraw!")
        _G.leapjump = false
    end
end

function M.buf_highlight_keeped_references(bufnr, references)
    local cursor_pos = util.get_cursor_pos()
    for _, reference in ipairs(references) do
        if config.under_cursor(bufnr) or not ref.is_pos_in_ref(cursor_pos, reference) then
            M.keeped_range(bufnr, reference[1], reference[2], reference[3])
        end
    end
    update()
end

function M.range(bufnr, start, finish, kind)
    local region = vim.region(bufnr, start, finish, "v", false)
    for linenr, cols in pairs(region) do
        if linenr == -1 then
            linenr = 0
        end
        local end_row
        if cols[2] == -1 then
            end_row = linenr + 1
            cols[2] = 0
        end
        vim.api.nvim_buf_set_extmark(bufnr, HL_NAMESPACE, linenr, cols[1], {
            hl_group = kind_to_hl_group(kind),
            end_row = end_row,
            end_col = cols[2],
            priority = 199,
            strict = false,
        })
    end
end

function M.keeped_range(bufnr, start, finish, kind)
    local region = vim.region(bufnr, start, finish, "v", false)
    for linenr, cols in pairs(region) do
        if linenr == -1 then
            linenr = 0
        end
        local end_row
        if cols[2] == -1 then
            end_row = linenr + 1
            cols[2] = 0
        end
        vim.api.nvim_buf_set_extmark(bufnr, HL_K_NAMESPACE, linenr, cols[1], {
            hl_group = keeped_kind_to_hl_group(kind),
            end_row = end_row,
            end_col = cols[2],
            priority = 300,
            strict = false,
        })
    end
end

function M.buf_clear_references(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, HL_NAMESPACE, 0, -1)
    update()
end

function M.buf_clear_keeped_references(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, HL_K_NAMESPACE, 0, -1)
    ref.buf_set_keeped_references(bufnr, {})
    update()
end

return M

local util = require("illuminate.util")
local ref = require("illuminate.reference")
local engine = require("illuminate.engine")

local M = {}

local ns = vim.api.nvim_create_namespace("illuminate_k_reference")
function M.Hl(current)
    local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	local sc = #ref.buf_get_keeped_references(bufnr)
	vim.api.nvim_buf_set_extmark(0, ns, vim.api.nvim_win_get_cursor(0)[1] - 1, 0, {
		virt_text = { { "[" .. current .. "/" .. sc .. "]", "illuminatedH" } },
		virt_text_pos = "eol",
	})

	vim.cmd("redraw")
end

function M.clear_keeped_hl()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function M.goto_next_reference(wrap)
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    i = i + 1
    if i > #ref.buf_get_references(bufnr) then
        if wrap then
            i = 1
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: goto_next_reference hit BOTTOM of the references")
            return
        end
    end
    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd("normal! m`")
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
end

function M.goto_nth_keeped_reference(n)
    local winid  = vim.api.nvim_get_current_win()
    local pos, b = unpack(ref.buf_get_keeped_references(bufnr)[n])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd("normal! m`")
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    M.Hl(n)
end

function M.goto_next_keeped_reference(wrap)
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_keeped_references(bufnr) == 0 then
        return
    end
    local i = ref.bisect_left(ref.buf_get_keeped_references(bufnr), cursor_pos)
    ::POS::
    if i > #ref.buf_get_keeped_references(bufnr) then
        if wrap then
            i = 1
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: goto_next_reference hit BOTTOM of the references")
            return
        end
    end
    local pos, b = unpack(ref.buf_get_keeped_references(bufnr)[i])
    if pos[1] == cursor_pos[1] and cursor_pos[2] <= b[2] and cursor_pos[2] >= pos[2] then
        if #ref.buf_get_keeped_references(bufnr) == 1 then
            goto END
        else
            i = i + 1
        end
        goto POS
    end
    ::END::
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd("normal! m`")
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
    M.Hl(i)
end

function M.goto_prev_reference(wrap)
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_references(bufnr), cursor_pos)
    i = i - 1
    if i == 0 then
        if wrap then
            i = #ref.buf_get_references(bufnr)
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: goto_prev_reference hit TOP of the references")
            return
        end
    end

    local pos, _ = unpack(ref.buf_get_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd("normal! m`")
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
end
function M.goto_prev_keeped_reference(wrap)
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local cursor_pos = util.get_cursor_pos(winid)

    if #ref.buf_get_keeped_references(bufnr) == 0 then
        return
    end

    local i = ref.bisect_left(ref.buf_get_keeped_references(bufnr), cursor_pos)
    i = i - 1
    if i == 0 then
        if wrap then
            i = #ref.buf_get_keeped_references(bufnr)
        else
            vim.api.nvim_err_writeln("E384: vim-illuminate: goto_prev_reference hit TOP of the references")
            return
        end
    end

    local pos, _ = unpack(ref.buf_get_keeped_references(bufnr)[i])
    local new_cursor_pos = { pos[1] + 1, pos[2] }
    vim.cmd("normal! m`")
    engine.freeze_buf(bufnr)
    vim.api.nvim_win_set_cursor(winid, new_cursor_pos)
    engine.unfreeze_buf(bufnr)
    M.Hl(i)
end


return M

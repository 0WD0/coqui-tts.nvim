local M = {}

-- 获取当前选中的文本
function M.get_selection_text()
	-- 获取当前选区
	local mode = vim.api.nvim_get_mode().mode
	if mode ~= 'v' and mode ~= 'V' then
		vim.notify("Please select text in visual mode or visual line mode first", vim.log.levels.WARN)
		return nil
	end

	local start_pos = vim.fn.getcharpos('v')
	local end_pos = vim.fn.getcharpos('.')

	if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
		start_pos, end_pos = end_pos, start_pos
	end

	if mode == 'V' then
		start_pos[3]= 1
		end_pos[3]= vim.fn.virtcol({end_pos[2],'$'})-1
	end

	return M.get_text_range(start_pos[2], start_pos[3], end_pos[2], end_pos[3])
end

function M.get_text_range(start_line, start_col, end_line, end_col)
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	if #lines == 0 then return '' end
	-- 使用vim.str_utfindex和vim.str_byteindex来处理UTF-8
	local start_idx = vim.str_byteindex(lines[1], vim.str_utfindex(lines[1], start_col - 1))
	lines[1] = string.sub(lines[1], start_idx + 1)
	if start_line == end_line then
		local end_idx = vim.str_byteindex(lines[1], vim.str_utfindex(lines[1], end_col))
		lines[1] = string.sub(lines[1], 1, end_idx)
	else
		local end_idx = vim.str_byteindex(lines[#lines], vim.str_utfindex(lines[#lines], end_col))
		lines[#lines] = string.sub(lines[#lines], 1, end_idx)
	end
	for i,line in pairs(lines) do
		-- lines[line] = vim.fn.substitute(lines[line], '\n$', '', '')
		vim.notify(line, vim.log.levels.INFO)
	end
	return table.concat(lines, '\n')
end

-- 播放音频
function M.play_audio(audio_file, audio_player)
	local cmd = string.format("%s %s", audio_player, audio_file)
	vim.fn.jobstart(cmd, {
		on_exit = function(_, code)
			if code ~= 0 then
				vim.notify("音频播放失败", vim.log.levels.ERROR)
			end
		end
	})
end

return M

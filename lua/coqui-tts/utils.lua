local M = {}

-- 获取当前选中的文本
function M.get_visual_selection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
	if #lines == 0 then return '' end

	-- 使用vim.str_utfindex和vim.str_byteindex来处理UTF-8
	local start_idx = vim.str_byteindex(lines[1], vim.str_utfindex(lines[1], s_start[3] - 1))
	lines[1] = string.sub(lines[1], start_idx + 1)

	if n_lines == 1 then
		local end_idx = vim.str_byteindex(lines[n_lines], vim.str_utfindex(lines[n_lines], s_end[3]))
		lines[n_lines] = string.sub(lines[n_lines], 1, end_idx)
	else
		local end_idx = vim.str_byteindex(lines[n_lines], vim.str_utfindex(lines[n_lines], s_end[3]))
		lines[n_lines] = string.sub(lines[n_lines], 1, end_idx)
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

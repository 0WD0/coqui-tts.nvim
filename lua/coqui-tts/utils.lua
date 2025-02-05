local config = require('coqui-tts.config')
local Job = require('plenary.job')

local M = {}

-- 获取当前选中的文本
function M.get_selection_text()
	-- 获取当前选区
	local mode = vim.api.nvim_get_mode().mode
	if mode ~= 'v' and mode ~= 'V' then
		vim.notify("Please select text in visual mode or visual line mode first", vim.log.levels.WARN)
		return nil
	end

	local start_pos = vim.fn.getpos('v')
	local end_pos = vim.fn.getpos('.')

	if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
		start_pos, end_pos = end_pos, start_pos
	end

	if mode == 'V' then
		start_pos[3]= 1
	end
	end_pos[3]= vim.fn.min({end_pos[3], vim.fn.col({end_pos[2],'$'})-1})

	return M.get_text_range(start_pos[2], start_pos[3], end_pos[2], end_pos[3])
end

function M.get_text_range(start_line, start_col, end_line, end_col)
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	if #lines == 0 then return '' end
	-- 使用vim.str_utfindex和vim.str_byteindex来处理UTF-8
	local start_idx = vim.str_byteindex(lines[1], vim.str_utfindex(lines[1], start_col - 1))
	local end_idx
	lines[1] = string.sub(lines[1], start_idx + 1)
	if start_line == end_line then
		end_col = end_col - start_col + 1
	end
	end_idx = vim.str_byteindex(lines[#lines], vim.str_utfindex(lines[#lines], end_col))
	lines[#lines] = string.sub(lines[#lines], 1, end_idx)
	return table.concat(lines, '\n')
end

-- 播放音频
function M.play_audio(audio_file, audio_player)
	Job:new({
		command = audio_player,
		args = { audio_file },
		on_exit = function(_, return_code)
			if return_code ~= 0 then
				vim.schedule(function()
					vim.notify("音频播放失败", vim.log.levels.ERROR)
				end)
			end
		end
	}):start()
end

-- 播放音频文件
function M.play_audio_file()
	M.play_audio(config.config.temp_audio_file, config.config.audio_player)
end

-- 重新播放最后一次生成的音频
function M.replay()
	-- 检查文件是否存在
	local stat = vim.loop.fs_stat(config.config.temp_audio_file)
	if stat and stat.type == "file" then
		M.play_audio(config.config.temp_audio_file, config.config.audio_player)
	else
		vim.schedule(function()
			vim.notify("没有可播放的音频文件", vim.log.levels.ERROR)
		end)
	end
end

-- 保存配置到文件
function M.save_config()
	-- 只保存需要持久化的配置项
	local persistent_config = {
		default_speaker = config.config.default_speaker,
		default_language = config.config.default_language,
	}

	local file = io.open(config.config.config_file, "w")
	if file then
		file:write(vim.json.encode(persistent_config))
		file:close()
		vim.notify("配置已保存", vim.log.levels.INFO)
	else
		vim.notify("无法保存配置文件", vim.log.levels.ERROR)
	end
end

-- 从文件加载配置
function M.load_config()
	local stat = vim.uv.fs_stat(config.config.config_file)
	if stat and stat.type == "file" then
		local file = io.open(config.config.config_file, "r")
		if file then
			local content = file:read("*a")
			file:close()
			local ok, persistent_config = pcall(vim.json.decode, content)
			if ok and persistent_config then
				-- 更新配置
				config.config = vim.tbl_deep_extend("force", config.config, persistent_config)
				vim.notify("配置已加载", vim.log.levels.INFO)
			else
				vim.notify("配置文件格式错误", vim.log.levels.WARN)
			end
		end
	end
end

return M

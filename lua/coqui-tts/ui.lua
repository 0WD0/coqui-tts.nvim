local config = require('coqui-tts.config')
local api = require('coqui-tts.api')
local utils = require('coqui-tts.utils')

local M = {}

-- 选择speaker
function M.select_speaker()
	api.get_model_info(function(model_info)
		vim.ui.select(model_info.speakers, {
			prompt = "选择Speaker:",
		}, function(choice)
			if choice then
				config.config.default_speaker = choice
				vim.notify("已设置speaker: " .. choice)
			end
		end)
	end)
end

-- 选择language
function M.select_language()
	api.get_model_info(function(model_info)
		vim.ui.select(model_info.languages, {
			prompt = "选择Language:",
		}, function(choice)
			if choice then
				config.config.default_language = choice
				vim.notify("已设置language: " .. choice)
			end
		end)
	end)
end

-- 朗读选中文本
function M.speak_text(opts)
	local text
	if opts and opts.range then
		local start_line = vim.fn.line("'<")
		local start_col = vim.fn.col("'<")
		local end_line = vim.fn.line("'>")
		local end_col = vim.fn.col("'>")
		text = utils.get_text_range(start_line, start_col, end_line, end_col)
	else
		text = utils.get_selection_text()
	end
	if text == "" then
		vim.notify("没有选中文本", vim.log.levels.WARN)
		return
	end

	api.send_tts_request(text, nil, nil, function(success)
		if success then
			utils.play_audio(config.config.temp_audio_file, config.config.audio_player)
		end
	end)
end

return M

local config = require('coqui-tts.config')
local ui = require('coqui-tts.ui')
local api = require('coqui-tts.api')
local command = require('coqui-tts.command')
local utils = require('coqui-tts.utils')

local M = {}

-- 检查依赖
local function check_dependencies()
	-- 检查 jq
	if vim.fn.executable('jq') ~= 1 then
		vim.notify("coqui-tts.nvim 需要 jq 来处理 URL 编码。请安装 jq：\n" ..
			"Ubuntu/Debian: sudo apt install jq\n" ..
			"macOS: brew install jq\n" ..
			"Arch Linux: sudo pacman -S jq", vim.log.levels.ERROR)
		return false
	end

	-- 检查 mpv
	if vim.fn.executable(config.config.audio_player) ~= 1 then
		vim.notify("coqui-tts.nvim 需要 " .. config.config.audio_player .. " 来播放音频。请安装：\n" ..
			"Ubuntu/Debian: sudo apt install " .. config.config.audio_player .. "\n" ..
			"macOS: brew install " .. config.config.audio_player .. "\n" ..
			"Arch Linux: sudo pacman -S " .. config.config.audio_player, vim.log.levels.ERROR)
		return false
	end

	return true
end

-- 初始化插件
function M.setup(opts)
	config.setup(opts)
	utils.load_config()  -- 加载保存的配置

	-- 设置命令
	command.setup()
	if not check_dependencies() then
		return
	end
end

-- 导出UI函数
M.select_speaker = ui.select_speaker
M.select_language = ui.select_language
M.speak_text = ui.speak_text

-- 导出API函数
M.refresh_model_info = api.refresh_model_info
M.send_tts_request = api.send_tts_request
M.get_model_info = api.get_model_info
M.replay = utils.replay

return M

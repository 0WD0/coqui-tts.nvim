local config = require('coqui-tts.config')
local ui = require('coqui-tts.ui')
local api = require('coqui-tts.api')

local M = {}

-- 导出配置设置函数
M.setup = config.setup

-- 导出UI函数
M.select_speaker = ui.select_speaker
M.select_language = ui.select_language
M.speak_text = ui.speak_text

-- 导出API函数
M.refresh_model_info = api.refresh_model_info

return M
local config = require('coqui-tts.config')
local Job = require('plenary.job')

local M = {}

-- 缓存模型信息
local model_info_cache = nil
local last_fetch_time = 0

-- 从服务器获取模型配置信息
function M.get_model_info(callback)
	-- 检查缓存是否有效
	local current_time = os.time()
	if model_info_cache and (current_time - last_fetch_time) < config.config.cache_ttl then
		vim.schedule(function()
			callback(model_info_cache)
		end)
		return
	end

	-- 使用plenary.job异步执行curl命令
	Job:new({
		command = 'curl',
		args = {
			'-s',
			'--connect-timeout', tostring(config.config.connect_timeout),
			config.config.server_url .. "/"
		},
		on_exit = function(j, return_code)
			if return_code ~= 0 then
				vim.schedule(function()
					vim.notify("获取模型信息失败: 服务器无响应", vim.log.levels.ERROR)
					if model_info_cache then
						vim.notify("使用缓存的模型信息", vim.log.levels.INFO)
						callback(model_info_cache)
					else
						callback({ speakers = {"default"}, languages = {"en"} })
					end
				end)
				return
			end

			local result = j:result()
			if #result == 0 then
				vim.schedule(function()
					vim.notify("获取模型信息失败: 服务器返回空响应", vim.log.levels.ERROR)
					if model_info_cache then
						vim.notify("使用缓存的模型信息", vim.log.levels.INFO)
						callback(model_info_cache)
					else
						callback({ speakers = {"default"}, languages = {"en"} })
					end
				end)
				return
			end

			local html = table.concat(result, "\n")
			local speakers = {}
			local languages = {}

			-- 解析select元素中的选项
			for option in html:gmatch('<option[^>]*value="([^"]*)"[^>]*>([^<]*)</option>') do
				local value, text = option:match('([^,]*),([^,]*)')
				if value and text then
					if text:match("Speaker") then
						table.insert(speakers, value)
					elseif text:match("Language") then
						table.insert(languages, value)
					end
				end
			end

			-- 如果没有找到，尝试从script标签中解析
			if #speakers == 0 or #languages == 0 then
				-- 寻找JavaScript变量定义
				local js_content = html:match('<script[^>]*>(.-)</script>')
				if js_content then
					-- 尝试匹配speakers数组
					for speaker in js_content:gmatch('speakers%s*=%s*%[([^%]]*)%]') do
						for value in speaker:gmatch('"([^"]*)"') do
							table.insert(speakers, value)
						end
					end
					-- 尝试匹配languages数组
					for language in js_content:gmatch('languages%s*=%s*%[([^%]]*)%]') do
						for value in language:gmatch('"([^"]*)"') do
							table.insert(languages, value)
						end
					end
				end
			end

			-- 更新缓存
			model_info_cache = {
				speakers = #speakers > 0 and speakers or {"default"},
				languages = #languages > 0 and languages or {"en"}
			}
			last_fetch_time = current_time

			vim.schedule(function()
				callback(model_info_cache)
			end)
		end,
	}):start()
end

-- 强制刷新模型信息缓存
function M.refresh_model_info(callback)
	model_info_cache = nil
	last_fetch_time = 0
	M.get_model_info(callback or function() end)
end

-- 发送TTS请求
function M.send_tts_request(text, speaker, language, callback)
	Job:new({
		command = 'curl',
		args = {
			'-s',
			'--connect-timeout', tostring(config.config.connect_timeout),
			string.format(
				'%s/api/tts?text=%s&speaker_id=%s&language_id=%s',
				config.config.server_url,
				vim.fn.shellescape(text),
				vim.fn.shellescape(speaker or config.config.default_speaker),
				vim.fn.shellescape(language or config.config.default_language)
			),
			'--output', config.config.temp_audio_file
		},
		on_exit = function(_, return_code)
			vim.schedule(function()
				if return_code ~= 0 then
					vim.notify("TTS请求失败", vim.log.levels.ERROR)
					callback(false)
				else
					callback(true)
				end
			end)
		end,
	}):start()
end

return M

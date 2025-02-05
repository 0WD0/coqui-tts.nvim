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

	vim.notify("正在获取模型信息...", vim.log.levels.INFO)

	-- 使用plenary.job异步执行curl命令
	Job:new({
		command = 'curl',
		args = {
			'-s',
			'--connect-timeout', tostring(config.config.connect_timeout),
			config.config.server_url .. "/"
		},
		on_stderr = function(_, data)
			if data then
				vim.schedule(function()
					vim.notify("Curl stderr: " .. vim.inspect(data), vim.log.levels.DEBUG)
				end)
			end
		end,
		on_exit = function(j, return_code)
			if return_code ~= 0 then
				vim.schedule(function()
					vim.notify("获取模型信息失败: 服务器无响应 (返回码: " .. return_code .. ")", vim.log.levels.ERROR)
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

			-- 分别提取speaker和language的select内容
			local speaker_select = html:match('id="speaker_id"[^>]*>(.-)</select>')
			local language_select = html:match('id="language_id"[^>]*>(.-)</select>')

			-- 解析speakers
			if speaker_select then
				for option in speaker_select:gmatch('value="([^"]+)"') do
					table.insert(speakers, option)
				end
			end

			-- 解析languages
			if language_select then
				for option in language_select:gmatch('value="([^"]+)"') do
					table.insert(languages, option)
				end
			end

			-- 如果没有找到，使用默认值
			if #speakers == 0 then
				speakers = {"default"}
			end
			if #languages == 0 then
				languages = {"en", "es", "fr", "de", "it", "pt", "pl", "tr", "ru", "nl", "cs", "ar", "zh-cn", "hu", "ko", "ja", "hi"}
			end

			-- 更新缓存
			model_info_cache = {
				speakers = speakers,
				languages = languages
			}
			last_fetch_time = current_time

			vim.schedule(function()
				vim.notify(string.format("找到 %d 个speakers和 %d 种语言", #speakers, #languages), vim.log.levels.INFO)
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
	-- URL 编码文本
	local encoded_text = vim.fn.system(string.format([[echo -n '%s' | jq -sRr @uri]], text))
	if vim.v.shell_error ~= 0 then
		vim.notify("URL编码失败", vim.log.levels.ERROR)
		callback(false)
		return
	end

	-- 移除末尾的换行符
	encoded_text = encoded_text:gsub("\n$", "")

	Job:new({
		command = 'curl',
		args = {
			'-s',
			'-X', 'POST',
			'-H', 'Content-Type: application/x-www-form-urlencoded',
			'--connect-timeout', tostring(config.config.connect_timeout),
			'--data', string.format(
				'text=%s&speaker_id=%s&language_id=%s',
				encoded_text,
				speaker or config.config.default_speaker,
				language or config.config.default_language
			),
			string.format('%s/api/tts', config.config.server_url),
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

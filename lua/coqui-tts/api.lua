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

			-- 解析select元素中的选项
			for option in html:gmatch('<option%s+value="([^"]+)"%s+SELECTED>[^<]+</option>') do
				if option then
					-- 检查是在哪个select中
					local before_chunk = html:match('(.-<option%s+value="' .. option .. '")')
					if before_chunk then
						if before_chunk:match('id="speaker_id"') then
							table.insert(speakers, option)
						elseif before_chunk:match('id="language_id"') then
							table.insert(languages, option)
						end
					end
				end
			end

			-- 如果没有找到，尝试从script标签中解析
			if #speakers == 0 or #languages == 0 then
				-- 寻找JavaScript变量定义
				local js_content = html:match('function%s+synthesize.-{(.-)}')
				if js_content then
					-- 提取默认值
					local default_speaker = js_content:match('speaker_id%s*=%s*"([^"]*)"')
					local default_language = js_content:match('language_id%s*=%s*"([^"]*)"')
					if default_speaker then
						table.insert(speakers, default_speaker)
					end
					if default_language then
						table.insert(languages, default_language)
					end
				end
			end

			-- 更新缓存
			model_info_cache = {
				speakers = #speakers > 0 and speakers or {"default"},
				languages = #languages > 0 and languages or {"en"}
			}

			vim.schedule(function()
				vim.notify("找到 " .. #speakers .. " 个speakers和 " .. #languages .. " 种语言", vim.log.levels.INFO)
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
			'-X', 'POST',
			'--connect-timeout', tostring(config.config.connect_timeout),
			string.format(
				'%s/api/tts?text=%s&speaker_id=%s&language_id=%s',
				config.config.server_url,
				encoded_text,
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

local M = {}

-- 默认配置
M.config = {
	server_url = "http://localhost:5002",
	default_speaker = "default",
	default_language = "en",
	audio_player = "mpv",  -- 需要系统安装mpv
	temp_audio_file = "/tmp/coqui_tts_output.wav",
	cache_ttl = 60 * 5,  -- 缓存时间（秒）
	connect_timeout = 5,  -- 连接超时（秒）
}

-- 设置配置
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M

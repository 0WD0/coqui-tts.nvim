local M = {}

-- 默认配置
M.default_config = {
	server_url = "http://localhost:5002",
	temp_audio_file = "/tmp/coqui_tts_output.wav",
	cache_ttl = 60 * 5,  -- 缓存时间（秒）
	connect_timeout = 5,  -- 连接超时（秒）
	audio_player = "mpv",
	default_speaker = "default",
	default_language = "en",
	config_file = vim.fn.stdpath("data") .. "/coqui-tts.json",  -- 配置文件路径
}

M.config = M.default_config

-- 设置配置
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M

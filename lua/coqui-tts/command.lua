local M = {}
function M.setup()
	-- 创建命令
	vim.api.nvim_create_user_command('CoquiSpeak', function(opts)
		require('coqui-tts').speak_text(opts)
	end, {range = true})

	vim.api.nvim_create_user_command('CoquiSelectSpeaker', function()
		require('coqui-tts').select_speaker()
	end, {})

	vim.api.nvim_create_user_command('CoquiSelectLanguage', function()
		require('coqui-tts').select_language()
	end, {})

	vim.api.nvim_create_user_command('CoquiRefreshInfo', function()
		require('coqui-tts').refresh_model_info()
	end, {})
	vim.api.nvim_create_user_command('CoquiReplay', function()
		require('coqui-tts').replay()
	end, {})
end
return M

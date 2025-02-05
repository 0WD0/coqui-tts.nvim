-- 创建命令
vim.api.nvim_create_user_command('CoquiSpeak', function()
    require('coqui-tts').speak_text()
end, {})

vim.api.nvim_create_user_command('CoquiSelectSpeaker', function()
    require('coqui-tts').select_speaker()
end, {})

vim.api.nvim_create_user_command('CoquiSelectLanguage', function()
    require('coqui-tts').select_language()
end, {})

vim.api.nvim_create_user_command('CoquiRefreshInfo', function()
    require('coqui-tts').refresh_model_info()
end, {})

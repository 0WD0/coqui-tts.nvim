# Coqui-TTS Neovim Plugin

这是一个Neovim插件，用于与Coqui-TTS服务器进行交互，可以将选中的文本转换为语音。

## 依赖

- Neovim 0.5+
- curl（用于发送HTTP请求）
- mpv（用于播放音频）
- 运行中的Coqui-TTS服务器
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)（用于HTML解析）

## 安装

使用你喜欢的插件管理器安装，例如使用 [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    'your-username/coqui-tts-server.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
        require('coqui-tts').setup({
            -- 可选配置
            server_url = "http://localhost:5002",
            default_speaker = "default",
            default_language = "en",
        })
    end
}
```

## 使用方法

1. 选择文本（可视模式）
2. 使用命令 `:CoquiSpeak` 将选中的文本转换为语音并播放

其他命令：
- `:CoquiSelectSpeaker` - 选择说话人
- `:CoquiSelectLanguage` - 选择语言

## 配置

默认配置：

```lua
require('coqui-tts').setup({
    server_url = "http://localhost:5002",
    default_speaker = "default",
    default_language = "en",
    audio_player = "mpv",
    temp_audio_file = "/tmp/coqui_tts_output.wav"
})

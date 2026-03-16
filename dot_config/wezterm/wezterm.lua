local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- フォント
config.font = wezterm.font('HackGen Console NF')
config.font_size = 14.0

-- カラースキーム
config.color_scheme = 'Tokyo Night'

-- ウィンドウ
config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.initial_rows = 40
config.initial_cols = 120

-- 透明化 + ブラー（濃いめ）
config.window_background_opacity = 0.80
config.macos_window_background_blur = 40

-- パフォーマンス（GPU加速）
config.front_end = "WebGpu"
config.max_fps = 120

-- tmux併用のため、weztermのタブバーは非表示
config.enable_tab_bar = false

-- 起動時にtmuxセッションに自動アタッチ（なければ新規作成）
config.default_prog = { '/opt/homebrew/bin/tmux', 'new-session', '-A', '-s', 'main' }

-- CMD+U で透明/不透明を切り替え
local is_transparent = true

wezterm.on('toggle-opacity', function(window)
  local overrides = window:get_config_overrides() or {}
  if is_transparent then
    overrides.window_background_opacity = 1.0
    overrides.macos_window_background_blur = 0
    is_transparent = false
  else
    overrides.window_background_opacity = 0.80
    overrides.macos_window_background_blur = 40
    is_transparent = true
  end
  window:set_config_overrides(overrides)
end)

-- キーバインド
config.keys = {
  { key = '=', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
  { key = 'u', mods = 'CMD', action = wezterm.action.EmitEvent('toggle-opacity') },
}

return config

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- フォント
config.font = wezterm.font('HackGen Console NF')
config.font_size = 22.0

-- フォントサイズ変更時にウィンドウサイズを変えない（Cmd+/-でレイアウトが暴れない）
config.adjust_window_size_when_changing_font_size = false

-- 日本語入力の安定化（IMEを有効化）
config.use_ime = true

-- ベル: 音は鳴らさず、カーソルを軽くフェードさせる
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = 'CursorColor',
}

-- インライン画像表示（`wezterm imgcat <file>` 等）
config.enable_kitty_graphics = true

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

-- カーソル
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500

-- tmux併用のため、weztermのタブバーは非表示
config.enable_tab_bar = false

-- ウィンドウを閉じる際の確認をスキップ（tmux側で管理）
config.window_close_confirmation = "NeverPrompt"

-- スクロールバック
config.scrollback_lines = 10000

-- 起動時にtmuxセッションに自動アタッチ（なければ新規作成）
config.default_prog = { '/opt/homebrew/bin/tmux', 'new-session', '-A', '-s', 'default' }

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
  -- Shift+Enter を Ctrl+J に変換（Claude Code の chat:newline デフォルト割当）
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendKey { key = 'j', mods = 'CTRL' } },
  -- VSCode 風ショートカット: Neovim 側で <C-A-X> として受信
  { key = 'd', mods = 'CMD', action = wezterm.action.SendKey { key = 'd', mods = 'CTRL|ALT' } },
  { key = 'a', mods = 'CMD|SHIFT', action = wezterm.action.SendKey { key = 'a', mods = 'CTRL|ALT' } },
  { key = 'p', mods = 'CMD', action = wezterm.action.SendKey { key = 'p', mods = 'CTRL|ALT' } },
  { key = 'p', mods = 'CMD|SHIFT', action = wezterm.action.SendKey { key = 'c', mods = 'CTRL|ALT' } },
  { key = 'f', mods = 'CMD', action = wezterm.action.SendKey { key = 'f', mods = 'CTRL|ALT' } },
  { key = '/', mods = 'CMD', action = wezterm.action.SendKey { key = '/', mods = 'CTRL|ALT' } },
  { key = 'w', mods = 'CMD', action = wezterm.action.SendKey { key = 'w', mods = 'CTRL|ALT' } },
  -- Ctrl+Shift+H/L をバッファ前後移動（Neovim 側で <C-A-h>/<C-A-l> として受信）
  { key = 'h', mods = 'CTRL|SHIFT', action = wezterm.action.SendKey { key = 'h', mods = 'CTRL|ALT' } },
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.SendKey { key = 'l', mods = 'CTRL|ALT' } },
}

-- マウス選択しただけでシステムクリップボードにコピーする
-- （デフォルトは PrimarySelection のみで、macOS ではクリップボードに入らない）
config.mouse_bindings = {
  -- ドラッグ選択の確定時（リンク上ならリンクを開くデフォルト挙動も維持）
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor 'ClipboardAndPrimarySelection',
  },
  -- ダブルクリック（単語選択）
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  -- トリプルクリック（行選択）
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
}

-- ファイルパスのハイパーリンクを CMD+クリックで tmux の隣 pane の nvim で開く
--
-- 公式 recipe (https://wezterm.org/recipes/hyperlinks.html) に沿って 2 層構成:
--  1. OSC-8 由来 `file://HOST/PATH#LINE` (ls --hyperlink, delta --hyperlinks,
--     rg --hyperlink-format=kitty 等) は wezterm.url.parse で正規化
--  2. プレーンテキスト由来 (Claude Code 等) は自前 regex で
--     `nvim-open:<path>#<line>` 形式の opaque URI に変換
--     ※ `nvim://~/...` だと `~` が URI authority と解釈され消えるため

local function get_tmux_active_pane_cwd()
  local handle = io.popen('/opt/homebrew/bin/tmux display-message -p "#{pane_current_path}" 2>/dev/null')
  if not handle then return nil end
  local result = handle:read('*l')
  handle:close()
  if result and result ~= '' then return result end
  return nil
end

-- 相対パスを tmux アクティブ pane の cwd で絶対化し、~ を展開する
local function resolve_file_path(path)
  if path:sub(1, 1) == '~' then
    path = (os.getenv('HOME') or '') .. path:sub(2)
  end
  if path:sub(1, 1) ~= '/' then
    local cwd = get_tmux_active_pane_cwd()
    if cwd then path = cwd .. '/' .. path end
  end
  return path
end

local function file_exists(path)
  local f = io.open(path, 'r')
  if f then f:close() return true end
  return false
end

local function spawn_nvim_in_tmux(pane, file_path, line)
  -- tmux のアクティブ pane の cwd を優先（wezterm 側 cwd は OSC-7 未送信時に古くなるため）
  local cwd = get_tmux_active_pane_cwd()
  if not cwd then
    local ok, cwd_obj = pcall(function() return pane:get_current_working_dir() end)
    if ok and cwd_obj then
      if type(cwd_obj) == 'string' then
        cwd = cwd_obj:gsub('^file://[^/]*', '')
      else
        cwd = cwd_obj.file_path or cwd_obj.path
      end
    end
  end

  local args = { '/opt/homebrew/bin/tmux', 'split-window', '-h' }
  if cwd and cwd ~= '' then
    table.insert(args, '-c')
    table.insert(args, cwd)
  end
  table.insert(args, '/opt/homebrew/bin/nvim')
  if line and line ~= '' then
    table.insert(args, '+' .. tostring(line))
  end
  table.insert(args, file_path)

  wezterm.log_info('nvim-open spawning: ' .. table.concat(args, ' '))
  wezterm.background_child_process(args)
end

-- 注意: このルールは必ずデフォルトルールの「後ろ」に追加すること。
-- wezterm はマッチ長の降順（同長ならルール定義順）でリンクを割り当てるため、
-- 先頭に挿入すると `https://example.com` のようなパスなし URL（デフォルトの
-- マッチと同長になる）がこのルールに奪われ、ブラウザで開けなくなる
local hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(hyperlink_rules, {
  regex = [==[(?<![A-Za-z0-9_])((?:~|\.{1,2}|/)?[^\s'"<>()\[\]{}|`]*?(?:[A-Za-z0-9_]\.[A-Za-z0-9]{1,10}|\.[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?))(?::(\d+))?(?::(\d+))?\b]==],
  format = 'nvim-open:$1#$2',
})
config.hyperlink_rules = hyperlink_rules

wezterm.on('open-uri', function(window, pane, uri)
  -- 層1: file://HOST/PATH#LINE (OSC-8 を吐くツール由来)
  local url = wezterm.url.parse(uri)
  if url and url.scheme == 'file' and url.file_path then
    spawn_nvim_in_tmux(pane, url.file_path, url.fragment)
    return false
  end

  -- 層2: nvim-open:PATH#LINE (regex 由来の opaque URI)
  if uri:match('^nvim%-open:') then
    local path, line = uri:match('^nvim%-open:(.+)#(%d*)$')
    if path then
      local abs = resolve_file_path(path)
      if file_exists(abs) then
        spawn_nvim_in_tmux(pane, abs, line)
      else
        wezterm.log_info('nvim-open: skip non-existent path: ' .. abs)
      end
    end
    return false
  end
end)

return config

Upstream: https://github.com/sonichi/sutando
Path: skills/image-generation/
License: MIT (see LICENSE)

ローカル変更:
- SKILL.md: 起動コマンドを `python3` から `$SKILL_DIR/.venv/bin/python` に変更（システム Python 汚染回避）
- SKILL.md: Requirements セクションを uv venv 構築手順に置換
- `.venv/` は chezmoi 非管理（デプロイ後に各端末で構築する）

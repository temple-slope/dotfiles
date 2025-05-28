#!/bin/bash

# 保存先ディレクトリを作成
secrets_dir="$HOME/.local/share/chezmoi/secrets"
mkdir -p "$secrets_dir"

# 登録したいシークレット一覧（key名: 表示名）
declare -A secrets=(
  [gitName]="your git name"
  [gitEmail]="your private git email"
)

echo "📦 Setting up secrets..."

for key in "${!secrets[@]}"; do
  read -p "Enter ${secrets[$key]}: " value
  echo "$value" > "$secrets_dir/$key"
  echo "✅ Saved: $key"
done

echo "🎉 All secrets saved in: $secrets_dir"

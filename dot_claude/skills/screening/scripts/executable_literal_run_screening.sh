#!/usr/bin/env bash
# screening スクリプト: 全スクリーニングエンドポイントを叩いてJSON結果を出力
# 使い方: ./run_screening.sh [fundamentals_url] [api_secret]
#   fundamentals_url: デフォルト http://localhost:8001
#   api_secret: デフォルト .env の API_SECRET

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

BASE_URL="${1:-http://localhost:8001}"

if [ -n "${2:-}" ]; then
    TOKEN="$2"
elif [ -f "$PROJECT_ROOT/.env" ]; then
    TOKEN="$(grep -E '^API_SECRET=' "$PROJECT_ROOT/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")"
else
    echo "ERROR: API_SECRET not found. Pass as argument or set in .env" >&2
    exit 1
fi

AUTH="Authorization: Bearer $TOKEN"
OUTDIR="$PROJECT_ROOT/reports/screening"
mkdir -p "$OUTDIR"

call_api() {
    local endpoint="$1"
    local label="$2"
    echo "  $label ..." >&2
    curl -sf -H "$AUTH" "${BASE_URL}${endpoint}" 2>/dev/null || echo '{"count":0,"data":[]}'
}

echo "=== Screening API calls ===" >&2

echo '{'

echo '"stats":'
call_api "/stats" "Stats"
echo ','

echo '"consecutive_growth":'
call_api "/screening/consecutive-growth?min_periods=3&limit=20" "B-1: Consecutive Growth"
echo ','

echo '"margin_improvement":'
call_api "/screening/margin-improvement?min_margin_change=1.0&limit=20" "B-2: Margin Improvement"
echo ','

echo '"forecast_revision":'
call_api "/screening/forecast-revision?min_revision_pct=10&limit=20" "B-3: Forecast Revision"
echo ','

echo '"eps_growth":'
call_api "/screening/eps-growth?min_eps_growth=20&limit=20" "B-4: EPS Growth"
echo ','

echo '"quality":'
call_api "/screening/quality?min_equity_ratio=50&min_roe=10&limit=20" "C: Quality"
echo ','

echo '"multi_factor":'
call_api "/screening/multi-factor?limit=20" "D-1: Multi-Factor"
echo ','

echo '"sector_relative":'
call_api "/screening/sector-relative?limit=20" "D-2: Sector Relative"

echo '}'

echo "=== Done ===" >&2

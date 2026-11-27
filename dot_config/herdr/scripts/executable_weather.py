#!/usr/bin/env python3
"""herdr のタブ行右端に出す天気（Open-Meteo、API キー不要）。

出力例: 大阪 ☀ 12°C 15/6 ☂30%（現在気温、今日の最高/最低、今日の降水確率の最大）
herdr はサーバー環境の python3（macOS 標準 3.9）で実行するため、3.9 互換・標準ライブラリのみで書く。
取得に失敗したら空行を出し、常に exit 0。
"""

import json
import urllib.request

NAME = "大阪"
LAT, LON = 34.6937, 135.5023
URL = (
    "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}"
    "&current=temperature_2m,weather_code"
    "&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max"
    "&timezone=Asia%2FTokyo&forecast_days=1"
).format(LAT, LON)


def icon(code):
    # WMO weather code
    if code == 0:
        return "☀"
    if code in (1, 2):
        return "⛅"
    if code == 3:
        return "☁"
    if code in (45, 48):
        return "🌫"
    if 51 <= code <= 67 or 80 <= code <= 82:
        return "☂"
    if 71 <= code <= 77 or code in (85, 86):
        return "❄"
    if code >= 95:
        return "⚡"
    return "?"


def main():
    with urllib.request.urlopen(URL, timeout=8) as res:
        d = json.load(res)
    cur, day = d["current"], d["daily"]
    text = "{} {} {}°C {}/{}".format(
        NAME, icon(cur["weather_code"]), round(cur["temperature_2m"]),
        round(day["temperature_2m_max"][0]), round(day["temperature_2m_min"][0]))
    pop = day["precipitation_probability_max"][0]
    if pop is not None:
        text += " ☂{}%".format(pop)
    print(text)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("")

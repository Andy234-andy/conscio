#!/bin/zsh
# �ASSWORD Conscio ランタイム健康診断 (進化#55)
# - プロセス生存・バージョン・バンドルID (プライバシー修正確認)
# - ネット接続数 (0だと完全オフラインの実証)
# - habitstats.json の書き込み様式確認 (アプリ切替イベント駆動)
APP="$HOME/Documents/Default Project/Conscio.app"
STATS=~/Library/Application\ Support/Conscio/habitstats.json

echo "== Conscio Health Check — $(date '+%F %T') =="
PID=$(pgrep -x Conscio)
echo "1) プロセス: ${PID:+alive (pid $PID)} ${PID:-⚠ NOT RUNNING}"

if [[ -n "$PID" ]]; then
  echo "2) バージョン: v$(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist") build $(plutil -extract CFBundleVersion raw "$APP/Contents/Info.plist")"
  echo "3) バンドルID: $(plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist") (com.atsuki.* であれば要修正!)"
  N=$(lsof -Pan -i -a -p "$PID" 2>/dev/null | grep -E "TCP|UDP" | wc -l | tr -d ' ')
  echo "4) ネット接続数: $N (0 = 完全オフライン実証 ✓)"
fi

if [[ -f "$STATS" ]]; then
  KB=$(du -k "$STATS" | awk '{print $1}')
  M=$(stat -f "%Sm" -t "%H:%M" "$STATS")
  echo "5) habitstats.json: ${KB}KB (最終書込 $M — 切替イベント駆動のため無操作時は不変が正常)"
  python3 -c "
import json
d = json.load(open('$HOME/Library/Application Support/Conscio/habitstats.json'))
bad = [k for k in ('usage','recentApps') for e in d.get(k,[]) if any(str(e).endswith(s) for s in ('.md','.txt','.pdf'))]
titles_like = [1 for e in d.get('usage',[]) if isinstance(e,dict) and any(k in e for k in ('title','url'))]
print('6) 保存中身の検査: 個人的タイトル/URLフィールド =', '⚠ 発見!' if titles_like else 'なし ✓ (アプリ名+秒数のみの設計どおり)')
"
else
  echo "5) habitstats.json: なし (未起動時)"
fi

#!/bin/zsh
# 🛡️ verify_release.sh — GitHub Releasesのzipを1コマンドで検証 (進化#60)
#
# 使い方:
#   ./Conscio/tools/verify_release.sh Conscio-v1.4.2.zip [期待SHA-256を省略可]
#   ./Conscio/tools/verify_release.sh Conscio-v1.4.2.zip 1ae2b6f94080a5dd83f54ee99f4dd5acac828acfb93d431808f65e2e18691055
#
# 何をやるか (シンプル・ネットワーク不要):
#  1. SHA-256 照合 (期待値を渡した場合一致/不一致を判定, 無しの場合は実際の値を表示)
#  2. zipを一時展開 → codesign --verify --deep --strict
#  3. バンドルID表示 (com.conscio.menubar = 中性化済)
#  期待値は SECURITY.md の §6.1 に一覧があります。

set -euo pipefail
ZIP="${1:?使い方: ./Conscio/tools/verify_release.sh <Conscio-v*.zip> [期待SHA-256]}"
EXPECTED="${2:-}"

if [ ! -f "$ZIP" ]; then
  echo "❌ ファイルが見つかりません: $ZIP"
  exit 1
fi

ACTUAL=$(shasum -a 256 "$ZIP" | awk '{print $1}')
if [ -n "$EXPECTED" ]; then
  if [ "$ACTUAL" = "$EXPECTED" ]; then
    echo "✅ SHA-256 一致: $ACTUAL"
  else
    echo "❌ SHA-256 不一致 — このzipは本物ではありません。再ダウンロードしてください。"
    echo "   実際: $ACTUAL"
    echo "   期待: $EXPECTED"
    exit 1
  fi
else
  echo "ℹ️  SHA-256: $ACTUAL"
  echo "   (SECURITY.md §6.1 の値と照合してください — 一致しない場合は使用しないでください)"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
ditto -x -k "$ZIP" "$TMP" 2>/dev/null
APP=$(find "$TMP" -maxdepth 2 -name "Conscio.app" -print | head -1)
if [ -z "$APP" ]; then
  echo "⚠ zip内に Conscio.app が見つかりません"
  exit 1
fi
codesign --verify --deep --strict "$APP" && echo "✅ codesign 検証通過 (ad-hoc署名)"
BID=$(plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist")
echo "ℹ️  バンドルID: $BID (中性化済の正常値 = com.conscio.menubar)"
echo "ℹ️  バージョン: $(plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist") build $(plutil -extract CFBundleVersion raw "$APP/Contents/Info.plist")"

#!/bin/zsh
# Conscio メトリクス収集スクリプト (🧬 進化#52: 日次スナップショットを metrics.log に自動追記)
# - GitHub: stars/forks/DL/view/uniques (gh)
# - Qiita: 全記事の PV (token2) — 行末に pv1..pv5 追加
# 同日"2回目"の実行は追記なし (1日1行の横並びで比較しやすくする)
REPO="Andy234-andy/conscio"
STAMP=$(date +%F)
DIR="$HOME/Documents/Default Project/Conscio/GROWTH"
LOG_FILE="$DIR/metrics.log"
TOKEN_FILE="$HOME/.conscio_qiita_token2"

STARS=$(gh api "repos/$REPO" --jq .stargazers_count 2>/dev/null)
FORKS=$(gh api "repos/$REPO" --jq .forks_count 2>/dev/null)
DL=$(gh api "repos/$REPO/releases" --jq '[.[].assets[].download_count] | add' 2>/dev/null)
TRAFFIC=$(gh api "repos/$REPO/traffic/views" --jq '"\(.count),\(.uniques)"' 2>/dev/null)
VIEWS=$(echo "$TRAFFIC" | cut -d, -f1)
UNIQUES=$(echo "$TRAFFIC" | cut -d, -f2)

ART_IDS=(9f1b6af7a9edc5b70968 041923a512b1c7b3328b dbd23baa4b3976dfdfae 22a016208cab808bba1a 1bd5641ad076e8e93cd0)
QPV=()
AUTH=()
[[ -f "$TOKEN_FILE" ]] && AUTH=(-H "Authorization: Bearer $(cat "$TOKEN_FILE")")
for id in "${ART_IDS[@]}"; do
  pv=$(curl -s --max-time 15 "${AUTH[@]}" "https://qiita.com/api/v2/items/$id" | python3 -c "import sys,json;print(json.load(sys.stdin).get('page_views_count'))" 2>/dev/null)
  QPV+=("${pv:-0}")
done

echo "📊 $STAMP — ⭐$STARS 🍴$FORKS 📦DL${DL:-0} 👀views${VIEWS:-0}/u${UNIQUES:-0} 🐝PV: ${QPV[1]} ${QPV[2]} ${QPV[3]} ${QPV[4]} ${QPV[5]}"

# 同日行の有無をチェックしてから1行追記
if ! grep -q "^$STAMP," "$LOG_FILE" 2>/dev/null; then
  echo "$STAMP,$STARS,$FORKS,${DL:-0},${VIEWS:-0},${UNIQUES:-0},${QPV[1]},${QPV[2]},${QPV[3]},${QPV[4]},${QPV[5]}" >> "$LOG_FILE"
  echo "✓ appended to metrics.log ($STAMP)"
else
  echo "ℹ️ $STAMP の行は既に存在 (1日1行)"
fi

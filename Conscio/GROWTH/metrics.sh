#!/bin/zsh
# Conscio メトリクス収集スクリプト (weekly snapshot)
REPO="Andy234-andy/conscio"
STAMP=$(date +"%Y-%m-%d")
LOG_FILE="$HOME/Documents/Default Project/Conscio/GROWTH/metrics.log"

echo "📊 Conscio 週次メトリクス — $STAMP"
echo "───────────────────────────────"

# GitHub stars / forks / watchers
GH_BASIC=$(gh api "repos/$REPO" --jq '"\(.stargazers_count),\(.forks_count)"' 2>/dev/null)
STARS=$(echo "$GH_BASIC" | cut -d, -f1)
FORKS=$(echo "$GH_BASIC" | cut -d, -f2)
echo "⭐ Stars: $STARS | 🍴 Forks: $FORKS"

# Release downloads
DL=$(gh api "repos/$REPO/releases" --jq '[.[].assets[].download_count] | add' 2>/dev/null)
echo "📦 Downloads: ${DL:-0}"

# Repo traffic (14日間)
TRAFFIC=$(gh api "repos/$REPO/traffic/views" --jq '"\(.count),\(.uniques)"' 2>/dev/null)
VIEWS=$(echo "$TRAFFIC" | cut -d, -f1)
UNIQUES=$(echo "$TRAFFIC" | cut -d, -f2)
echo "👀 Repo Views (14d): ${VIEWS:-0} | 👤 Uniques: ${UNIQUES:-0}"

# Git clones (14日間)
CLONES=$(gh api "repos/$REPO/traffic/clones" --jq '"\(.count),\(.uniques)"' 2>/dev/null)
echo "🔁 Clones (14d): $(echo "$CLONES" | cut -d, -f1)"

echo "───────────────────────────────"
# CSVに追記 (トレンド追跡用)
mkdir -p "$(dirname "$LOG_FILE")"
if [ ! -f "$LOG_FILE" ]; then
  echo "date,stars,forks,downloads,views14d,uniques14d" >> "$LOG_FILE"
fi
echo "$STAMP,$STARS,$FORKS,${DL:-0},${VIEWS:-0},${UNIQUES:-0}" >> "$LOG_FILE"
echo "💾 metrics.log に追記済み: $LOG_FILE"

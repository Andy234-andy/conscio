#!/bin/zsh
# 📊 qiita_table.sh — 連載Qiitaダッシュボード表 (進化#73定着・進化#80で6本化)
# ユーザー要望「毎回の最後に投稿時間・閲覧数・スター数等の表を載せて」→ 毎ティックの最終メッセージ末尾で実行する
# 使い方: ./Conscio/tools/qiita_table.sh   → Markdown表を出力 (そのまま会話/記録に貼る)
# 実装メモ: HTTPはcurl (macOSのpython urllibはSSL証明書検証で失敗するため)
TOKEN="${CONSCIO_QIITA_TOKEN:-$(cat "$HOME/.conscio_qiita_token2" 2>/dev/null)}"
if [ -z "$TOKEN" ]; then
  echo "❌ Qiita token が見つかりません (~/.conscio_qiita_token2)"
  exit 1
fi

TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT

IDS=(9f1b6af7a9edc5b70968 041923a512b1c7b3328b dbd23baa4b3976dfdfae 22a016208cab808bba1a 1bd5641ad076e8e93cd0 f641539d82818d7693e0)
i=0
for id in "$IDS[@]"; do
  i=$((i+1))
  curl -s --max-time 15 "https://qiita.com/api/v2/items/$id" -H "Authorization: Bearer $TOKEN" -o "$TDIR/$i.json" 2>/dev/null
done

CONSCIO_QT_DIR="$TDIR" python3 - <<'PYEOF'
import json, os

base = os.environ["CONSCIO_QT_DIR"]
IDS_N = 6

print("| # | タイトル | 投稿 (JST) | PV | ❤ | 📚 | 💬 | タグ |")
print("|---|----------|-----------|---:|---:|---:|---:|------|")

tot = [0, 0, 0, 0]
ok = 0
for n in range(1, IDS_N + 1):
    try:
        with open(f"{base}/{n}.json", "rb") as f:
            d = json.load(f)
        # エンドポイント仕様の縦持ち辞書をフラットに整形
        if not isinstance(d, dict):
            raise TypeError("not dict")
        t = d.get("title", "")
        t = t[:14] + "…" if len(t) > 14 else t
        c = d.get("created_at", "")[:16].replace("T", " ")
        if not c:
            raise KeyError("created_at")
        pv, lk = d.get("page_views_count", 0), d.get("likes_count", 0)
        st, cm = d.get("stocks_count", 0), d.get("comments_count", 0)
        tg = "·".join(x["name"] for x in d.get("tags", [])[:2])
        print(f"| Art#{n} | {t} | {c} | {pv:,} | {lk} | {st} | {cm} | {tg} |")
        tot = [tot[k] + v for k, v in enumerate([pv, lk, st, cm])]
        ok += 1
    except Exception as e:
        print(f"| Art#{n} | (取得失敗: {type(e).__name__}) | - | - | - | - | - | - |")

if ok:
    print(f"| | **合計 ({ok}本)** | | **{tot[0]:,}** | **{tot[1]}** | **{tot[2]}** | **{tot[3]}** | |")
PYEOF

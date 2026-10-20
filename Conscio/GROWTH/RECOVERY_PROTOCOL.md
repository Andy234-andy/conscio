# 🛟 Conscio ループ復旧プロトコル（止まった時用）
*作成: 2026-10-18 10:55 / 目的: どんな理由で会話やループが止まっても、何かのきっかけ（ユーザーの1メッセージ・タイマー発火・新セッション開始）で復帰した誰（=将来の私）でも30秒で再始動できる手順書*

## 復帰手順（この順で実行）
1. `date` で現在時刻確認 → `GROWTH/loop_state.txt` の `heartbeat:` と比較。
   **差が32分超 = 「死んでいた」と判定 → 復旧モード開始**
2. `Conscio/RULES.md` を読む（絶対規則・変更禁止）
3. `Conscio/GROWTH/EVOLUTION_BACKLOG.md` の最初の ⬜ タスクを取得
4. 以下の3連撃を background shell でアーム（自己修復の心臓部）:
   ```
   MAIN:      sleep 1800;  echo 'AGENT_LOOP_WAKE_main {"role":"main","prompt":"<標準ティック指示>"}'
   BACKUP:    sleep 2820;  echo 'AGENT_LOOP_WAKE_backup {"role":"backup"}'
   EMERGENCY: sleep 10800; echo 'AGENT_LOOP_WAKE_emergency {"role":"emergency"}'
   ```
5. 復旧ティックを実行: backlogタスク実装 →swift build緑 → 本Appに反映 → commit/push → README進化ログ更新 → day_report追記 → heartbeat 更新
6. caffeinate が生きているか `pgrep caffeinate` で確認、無ければ `nohup caffeinate -i &`
7. 標準ティック指示の末尾に「**⑥ `./Conscio/GROWTH/metrics.sh` 実行(1日1行自動)**」を含めること（進化#63で結線済み — 忘れると当日行が欠落する）
8. 標準ティック指示に「**⑧ ティックの最終メッセージ末尾に `./Conscio/tools/qiita_table.sh` のQiitaダッシュボード表を必ず載せる**」を含めること（進化#73定着・2026-10-20のユーザー要望「毎回の最後に投稿時間・閲覧数・スター数等の表を」）

## ツールSET（進化#55/#60で定着・復旧後の点検に使う）
| ツール | 用途 | 実行 |
|--------|------|------|
| `tools/health_check.sh` | プロセス生存・バージョン・バンドルID・**ネット接続0の実測**・保存データ検査 | `./Conscio/tools/health_check.sh` |
| `tools/verify_release.sh` | リリースzipのSHA-256+codesign検証（不一致はexit 1） | `./Conscio/tools/verify_release.sh <zip> [期待SHA]` |
| `GROWTH/metrics.sh` | 日次メトリクス行の自動追記（同日2回目はスキップ） | `./Conscio/GROWTH/metrics.sh` |
| `tools/qiita_table.sh` | Qiita連載5記事のダッシュボード表（投稿時刻/PV/❤/📚/💬/タグ）をティックの最終メッセージ末尾に必ず載せる（進化#73・ユーザー要望）| `./Conscio/tools/qiita_table.sh` |
| `GROWTH/USER_CHECKIN.md` | ユーザー来訪時の保留判断リスト（勝手に編集せず提案で置くこと） | 読むだけ |

## 挙動ルール（増殖を防止する）
- **BACKUP / EMERGENCY が発火したとき**: heartbeat が新鮮（≤32分）なら**何もせず静かに消える**（リアームしない）。これで多重ループは増えない
- **MAIN はtickの最初に必ずリアームする**（自分が死んでも次がいる状態を先に作る）
- どのwakeも最初に loop_state.txt を見る。自分が pending リストに無く heartbeat が新鮮なら孤児wake=静かに退場
- 出先（user-away）でも: GitHub操作はユーザー既承認。v1.xのリリース手順は確立済み（AI表明入りnotes + zip + SHA-256をSECURITY.mdに追記。現行 v1.4.2）。**公開コンテンツの変更（Qiita記事編集・note編集）は従来承認済みでも別途ユーザー承認を取り直す**（USER_CHECKINの提案欄に積む）
- ❌ 絶対禁止: 課金・個人情報・炎上表現・SNSへの新規自動投稿（Qiita等はトークンがある場合のみユーザー承認済みの範囲で）
- **ループの全面停止／再開はユーザーメッセージにのみ従う**（「ループ止めて」で全sleepers SIGTERM+caffeinate停止・loop_stateをSTOPPEDに。再開は新しいユーザーメッセージが必須）

## 実録の先例（復旧判断に使う実際のケース）
1. **夜間全面停止→朝の再開** (10/19): ユーザーの「ループ止めて」で3レーン+caffeinateを全部停止・loop_state=STOPPED。翌朝ユーザーの1メッセージで本手順どおり復活 → tickを1本消化せず無駄にしない
2. **backup誤アラーム (13:51, gap39分)**: backup発火時、heartbeatが32分超でも**直近のコミットが新しければ「稼働ドリフト」と判定**してログだけ取り無言退場。復旧モードを無闇に起こさない
3. **stale binary のハンドノート** (進化#33): build直後は `ls -la $(swift build --show-bin-path)/Conscio` のmtime新鮮を確認してからバンドル。Package.swiftのみの変更ならバイナリ同一 → アプリ再起動を省く

## 「会話止まった場合」の現実的な挙動
- OpenCode の background shell は agent を起こせるので、**タイマーが尽きるたびに自動で私が復帰**する
- 万が一セッションごと終わっても、ユーザーが**何か1文字打つだけで**この手順書に沿って復活する（loop_state.txt と手順書は push 済み = 世界に保存される）

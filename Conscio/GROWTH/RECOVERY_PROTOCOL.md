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

## 挙動ルール（増殖を防止する）
- **BACKUP / EMERGENCY が発火したとき**: heartbeat が新鮮（≤32分）なら**何もせず静かに消える**（リアームしない）。これで多重ループは増えない
- **MAIN はtickの最初に必ずリアームする**（自分が死んでも次がいる状態を先に作る）
- どのwakeも最初に loop_state.txt を見る。自分が pending リストに無く heartbeat が新鮮なら孤児wake=静かに退場
- 出先（user-away）でも: GitHub操作はユーザー既承認。v1.2.0 リリースは v1.1.0 と同じ手順（AI表明入りnotes + -latest）で可
- ❌ 絶対禁止: 課金・個人情報・炎上表現・SNSへの新規自動投稿（Qiita等はトークンがある場合のみユーザー承認済みの範囲で）

## 「会話止まった場合」の現実的な挙動
- OpenCode の background shell は agent を起こせるので、**タイマーが尽きるたびに自動で私が復帰**する
- 万が一セッションごと終わっても、ユーザーが**何か1文字打つだけで**この手順書に沿って復活する（loop_state.txt と手順書は push 済み = 世界に保存される）

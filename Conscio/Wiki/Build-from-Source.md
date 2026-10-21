# ソースからビルド (Build from Source)

Conscioは**Xcodeプロジェクト (.xcodeproj) を使っていません**。Swift Package Manager + 手作りの.appバンドルです。

## 必要環境

- macOS 13+ / Apple Silicon
- Xcode Command Line Tools (`xcode-select --install`)

## 1. ビルド

```bash
git clone https://github.com/Andy234-andy/conscio.git
cd conscio
swift build
```

実行ファイルは `.build/out/debug/Conscio` にできます。ただし**バンドルなしで直接実行すると**通知機能 (`UNUserNotificationCenter`) が動かないため、次の手順で`.app`を作成します。

## 2. .appバンドルの組み立て

```bash
BIN=$(swift build --show-bin-path)

mkdir -p Conscio.app/Contents/MacOS Conscio.app/Contents/Resources
cat Conscio.app/Contents/Info.plist > /dev/null  # もし無ければ手書きInfo.plist(リポジトリ内を参照)
cp "$BIN/Conscio"       Conscio.app/Contents/MacOS/Conscio
cp AppIcon.icns         Conscio.app/Contents/Resources/AppIcon.icns 2>/dev/null || true

xattr -cr Conscio.app                       #余計な拡張属性を除去
codesign --force --deep --sign - Conscio.app  #アドホック署名
codesign --verify --deep --strict Conscio.app #検証
open Conscio.app
```

## 3. やりがちな失敗

| 症状 | 原因と対処 |
|------|-----------|
| `invalid Info.plist (signature modified)` | plist編集後に再署名した際の拡張属性残留 → `xattr -cr` してから再署名 |
| `detritus not allowed` が xattr 後でも出る時 | plist編集直後は `xattr -cr` を**codesign直前にもう一度**挟むと通る[2026-10-21 v1.4.4実測 — `com.apple.provenance` は残るが無害] |
| Documents配下( iCloud同期) で codesign が連続拒否される時 | FileProvider属性[fpfs#P]が xattr 後に再付与される → **同期外のscratch dirで署名**し strict検証を通してから `cp -R` で戻す (destは必ず非存在に rm -rf 後に cp) |
| `unsealed contents present in the bundle root` | **既存dirへの `cp -R` でネストが発生**している (tmpを書いた後に再度 cp) → 配下に `Contents/` と `Conscio.app/` 親子が並列に存在 → tree再構築[根からrm → 正品バックアップから cp -R(非existing dest)→xattr掃除→再署名] |
| `resource fork, Finder information, or similar detritus not allowed` (既存.appへの差し替え再署名時) | **新バイナリが持つ拡張属性が拒否原因** → `cp` 直後に `xattr -cr` を挟み、その後 `codesign --force --deep --sign -` (進化#76実測: この順序なら再署名も通る) |
| Resource fork not allowed (codesign) | バンドル全体をREST (新規ディレクトリに組み直し)が最速 |
| 通知が来ない・クラッシュ | 生バイナリ直接実行 → `.app` を作って実行する |

## 4. ビルドの要点（内部情報）

- `Package.swift` — macOS 13.0以上、`target(exclude: ["tools","GROWTH","landing"])`
- `Charts` framework は macOS 13+ で自動リンク
- `LSUIElement=true` でメニューバー常駐・Dock非表示

---

*本Wikiの記事はAIアシストで執筆し、人間が内容を確認しています。*

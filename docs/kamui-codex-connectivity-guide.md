# Kamui × Codex 疎通ガイド（実運用向け）

最終更新: 2026-02-20 (UTC)

このガイドは、**Codex/OpenClaw から Kamui の MCP ツール群へ接続する仕組み**と、
接続できないときの切り分け手順をまとめたものです。

---

## 1) 全体構成（どう繋がっているか）

Codex が直接 Kamui API を叩くのではなく、次の経路で呼び出します。

1. Codex / OpenClaw から `exec` で `mcporter` を実行
2. `mcporter` が設定ファイル（例: `/home/flock_h/daisy/config/mcporter.json`）を読む
3. 設定内の MCP Server（HTTP）へリクエスト
4. Kamui 側エンドポイント（`https://kamui-code.ai/...`）へ到達
5. Kamui が FAL 等のバックエンドを実行

要点:
- 認証は **HTTPヘッダ `KAMUI-CODE-PASS`**
- 実体は環境変数 **`KAMUI_CODE_PASS_KEY`** から代入

---

## 2) 設定ファイルのキモ

実際の設定（抜粋）はこの形式:

```json
{
  "mcpServers": {
    "t2v-kamui-fal-xai-grok-imagine-video-text-to-video": {
      "type": "http",
      "url": "https://kamui-code.ai/t2v/fal/xai/grok-imagine-video/text-to-video",
      "headers": {
        "KAMUI-CODE-PASS": "${KAMUI_CODE_PASS_KEY}"
      }
    }
  }
}
```

つまり、`KAMUI_CODE_PASS_KEY` が未設定だと **全サーバーが一斉に失敗**します。

---

## 3) いま起きている典型エラー

`mcporter list` で次が出る場合:

> Failed to resolve header 'KAMUI-CODE-PASS' ... Environment variable(s) KAMUI_CODE_PASS_KEY must be set

これはネットワーク障害ではなく、**認証ヘッダ組み立て前に落ちている**状態です。

---

## 4) 最短の疎通確認手順（順番厳守）

### Step 1. mcporter 自体の動作確認

```bash
mcporter --version
```

### Step 2. 設定ファイルが読めるか

```bash
mcporter --config /home/flock_h/daisy/config/mcporter.json list --output json
```

### Step 3. 環境変数の有無確認

```bash
printenv KAMUI_CODE_PASS_KEY | wc -c
```

- `0` なら未設定
- 1以上なら値あり（値そのものは表示しない）

### Step 4. 単発で環境変数を注入して再確認（テスト）

```bash
KAMUI_CODE_PASS_KEY='***' \
mcporter --config /home/flock_h/daisy/config/mcporter.json list --output json
```

※ `***` は実キー。履歴に残したくない場合は shell の安全手段を使う。

### Step 5. ツール呼び出しの最小テスト

```bash
KAMUI_CODE_PASS_KEY='***' \
mcporter --config /home/flock_h/daisy/config/mcporter.json \
call t2i-kamui-fal-gemini-3-pro-image-preview.gemini_3_pro_image_preview_submit \
prompt='connectivity test image' num_images=1 aspect_ratio='1:1' sync_mode=true
```

---

## 5) なぜ「Codexでは失敗、手元では成功」が起こるか

ほぼこれです:

- ターミナルAでは `export KAMUI_CODE_PASS_KEY=...` 済み
- でも OpenClaw/Codex 実行プロセスは別セッションで起動
- そのセッションには環境変数が引き継がれていない

対策:
- OpenClaw を起動する親プロセスに環境変数を渡す
- もしくは呼び出しコマンドに都度プレフィックス注入する

---

## 6) 実運用での安全な注入パターン

### A. 実行時プレフィックス（簡易）

```bash
KAMUI_CODE_PASS_KEY='***' mcporter --config ... call ...
```

### B. サービス起動時に環境設定（推奨）

- systemd user service / 起動スクリプト側で `Environment=KAMUI_CODE_PASS_KEY=...`
- これで Codex 側からの `exec` でも安定利用しやすい

---

## 7) 動画ワークフローで使う主要サーバー

- `file-upload-kamui-fal`
  - ローカル画像をURL化（i2v 前段）
- `t2v-kamui-fal-xai-grok-imagine-video-text-to-video`
  - テキスト→動画
- `i2v-kamui-fal-xai-grok-imagine-video-image-to-video`
  - 画像→動画（末尾フレーム連鎖に必須）

補助:
- `t2i-kamui-kling-image-v3`
- `i2i-kamui-kling-image-v3`

---

## 8) 障害切り分けチェックリスト

1. `mcporter --version` は通るか
2. `--config` パスは正しいか
3. `KAMUI_CODE_PASS_KEY` はその実行コンテキストで見えるか
4. `mcporter list --output json` で `error` の文言は何か
5. 403/401 ならキー不正、DNS/timeout ならネットワーク
6. まず t2i の軽い同期呼び出しで疎通確認後、動画系へ進む

---

## 9) トラブル時の読み方（エラー別）

- `Failed to resolve header ... KAMUI_CODE_PASS_KEY must be set`
  - 環境変数未設定
- `401/403`
  - キー値ミス・期限切れ・権限問題
- `ENOTFOUND / timeout`
  - ネットワーク・DNS・疎通経路
- `429`
  - レート制限（待機/retry）
- `insufficient credits`
  - 残高不足

---

## 10) 実務メモ（推奨運用）

- まず **軽い t2i 同期**で毎回ヘルスチェック
- 問題なければ i2v/t2v の本番ジョブへ
- 失敗時は「認証/通信/残高/レート」の順で切り分け
- 秘密値はドキュメントやGitに絶対に書かない

---

このガイドに沿えば、
「CodexがKamuiに繋がらない」問題はほぼ再現・解決できます。

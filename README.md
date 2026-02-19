# 🎬 Video Project Lab

AI動画制作の実験・作品アーカイブ。

## 目的
- キャラクター一貫性を保った動画生成ワークフローを確立する
- プロンプト設計・生成パイプライン・運用ノウハウを蓄積する
- 作品を継続的に公開して改善する

## 現在の基本ワークフロー
1. **Reference Image** を用意
2. **Kling Image O1 (I2I)** で「同一キャラの別シーン」を作る
3. **Grok Imagine Video (I2V)** で動画化
4. Discordでレビュー → 次のプロンプトへ反映

## 学んだこと（Lessons Learned）

### 1) キャラ一貫性
- いきなり動画化より、**先に静止画で別シーンを作ってから動画化**した方が安定する
- 参照画像 + シーン固有の行動（例: 走る/振り返る/見上げる）を明示すると崩れにくい

### 2) プロンプト設計
- 「このシーンから始めない」を明文化すると、同じ構図の再出力を避けやすい
- カメラワーク（push in / orbit / handheld）を入れると映像の意図が通りやすい

### 3) 運用
- Kamui/FALは**レートリミット**と**残高**の2軸で詰まることがある
- 失敗時はワンショットcronでリトライ戦略を組むと運用が安定する

## 作品（Works）

### Character Reference Videos (Grok I2V)
- Meadow Run: https://v3b.fal.media/files/b/0a8ed5cf/yigUuPv8RL5n9mnx8r5Xj_GK4K8I1g.mp4
- Spaceship Awe: https://v3b.fal.media/files/b/0a8ed5cf/4l1U3mYiE5vC4mA4kIYoA_0DtnFzD.mp4
- Shibuya Rain Walk: https://v3b.fal.media/files/b/0a8ed5cf/9xQp8N1k7Qv2sKa2E9xF0_q2M8bJ1.mp4

> NOTE: 作品URLは一定期間で失効する可能性あり。今後はリリース資産または外部ストレージ保管を検討。

## Next
- [ ] 作品保存先の恒久化（GitHub Releases / Cloud storage）
- [ ] テンプレート化（scene prompt pack）
- [ ] 週次でベストショットを選出


<p align="center">
  <img src="assets/icon.png" width="96" alt="CursorUsageBar" />
</p>

<h1 align="center">CursorUsageBar</h1>

<p align="center">
  macOS メニューバーで Cursor プラン使用量 — Included ドル、プール %、Credits、Slow pool。
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md"><b>日本語</b></a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <img src="assets/hero.png" width="880" alt="CursorUsageBar プレビュー" />
</p>

<p align="center">
  <img src="assets/menu-preview.png" width="560" alt="メニュープレビュー" />
</p>

<p align="center">
  <code>./install.sh</code> — ビルド、<code>~/Applications</code> へインストール、起動。API キー・Keychain なし。
</p>

---

## インストール

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

**要件:** macOS 14+、Xcode CLT / Swift 5.9+、この Mac で Cursor IDE に一度以上サインイン。

## 表示項目

| 項目 | 意味 |
| --- | --- |
| リング / ツールチップ | 表示用 total % · included `$使用/$上限` · Slow pool（有効時） |
| 見出し | ドル枯渇時は “Included limit reached”、それ以外は Cursor の % メッセージ |
| Included | プラン **$ 使用 / $ 上限** — 枯渇の目安 |
| Pools | Auto · API · Total 表示 % |
| On-demand | 従量（有効時） |
| Credits | プロモクレジット（ある場合） |
| Slow pool | Auto のみ遅延キュー（有効時） |
| Meta | プラン · 請求サイクル更新 |

アプリ内 % はドルとずれることがあるため、両方表示します。

### 更新

| 状況 | 間隔 |
| --- | --- |
| 直近 5 分以内にメニューを開いた | 1 分 |
| アイドル | 5 分 |
| メニュー / **Refresh**（`r`） | 即時 |

## 仕組み

ローカル `state.vscdb` から `cursorAuth/accessToken` を読み（読み取り専用、Keychain なし）、並列取得:

- `GET https://cursor.com/api/usage-summary`
- `POST …/GetUsageLimitStatusAndActiveGrants`

非公式ダッシュボード API — 公式 Cursor 製品ではありません。

## アンインストール

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
```

## ライセンス

MIT

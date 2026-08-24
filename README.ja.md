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
  <img src="assets/hero.png" width="380" alt="CursorUsageBar プレビュー" />
</p>

<p align="center">
  <code>./install.sh</code> — ビルド、<code>~/Applications</code> へインストール、起動。API キー・Keychain なし。
</p>

---

## なぜ

Cursor アプリ内の **% は遅延したり**、実際の Included **$ 使用/上限**と **一致しない**ことがあります。CursorUsageBar はメニューバーで両方を表示し、Included ドルの枯渇や Credits・Slow pool の適用をすぐ確認できます。

## インストール

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

リリースビルド → WAL-safe セッション DB 読み取り検証 → `~/Applications/CursorUsageBar.app` インストール → 起動。

**要件:** macOS 14+、Xcode CLT / Swift 5.9+、この Mac で Cursor IDE に一度以上サインイン（トークンはローカル `state.vscdb`、IDE 起動不要）。

## 表示項目

| 項目 | 意味 |
| --- | --- |
| メニューバー円グラフ / ツールチップ | 表示用 total % · included `$使用/$上限` · Slow pool（有効時） |
| 見出し | ドル枯渇時は “Included limit reached”、それ以外は Cursor の % メッセージ |
| Included | `$使用 / $上限` + `· exhausted` または `· $X left` |
| Pools | Auto · API · Total 表示 % |
| On-demand | `$使用 / $上限`、`$使用 used`、または `off` |
| Credits | `$残 / $総 · 期限` — プロモ grant なしなら非表示 |
| Slow pool | 遅延キュー — Auto only または limited models · grant $ · ~delay — 非活性時は非表示 |
| Meta | 例: `pro · resets Sep 17 (23d)` |

### メニュー操作

| 操作 | |
| --- | --- |
| **Refresh** (`r`) | 最新使用量を取得 |
| **Open Dashboard** (`o`) | [cursor.com/dashboard/spending](https://cursor.com/dashboard/spending) |
| **Quit** (`q`) | 終了 |

### 更新

| 状況 | 間隔 |
| --- | --- |
| 直近 5 分以内にメニューを開いた | 1 分 |
| アイドル | 5 分 |
| メニュー / **Refresh**（`r`） | 即時 |

## 仕組み

1. `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` から  
   `cursorAuth/accessToken` を読み取り（`mode=ro&immutable=1` — **Keychain なし**）
2. JWT `sub` からダッシュボード Cookie を生成
3. **並列**取得:
   - `GET https://cursor.com/api/usage-summary` — Included $、プール %、on-demand、プラン/サイクル
   - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants` — Credits + Slow pool
4. Credits / Slow pool は **best-effort** — grants RPC が失敗しても基本使用量は表示

非公式ダッシュボード API — **公式 Cursor 製品ではありません**。トークンは refresh ごとに読み取るだけで書き込みません。

## プライバシー

リポジトリにトークン・メール・端末パスは含まれません。実行時は **お使いの Mac** のローカル Cursor セッションのみ読み取ります。

## アンインストール

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# ログイン項目に追加した場合は削除
```

## ライセンス

MIT

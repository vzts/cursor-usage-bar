<p align="center">
  <img src="assets/icon.png" width="96" alt="CursorUsageBar" />
</p>

<h1 align="center">CursorUsageBar</h1>

<p align="center">
  Cursor plan usage in the macOS menu bar — included dollars, pool %, credits, slow pool.
</p>

<p align="center">
  <a href="README.md"><b>English</b></a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <img src="assets/hero.png" width="880" alt="CursorUsageBar preview" />
</p>

<p align="center">
  <img src="assets/menu-preview.png" width="560" alt="Menu preview" />
</p>

<p align="center">
  <code>./install.sh</code> — build, install to <code>~/Applications</code>, launch. No API key. No Keychain prompt.
</p>

---

## Install

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

**Requirements:** macOS 14+, Xcode CLT / Swift 5.9+, Cursor IDE signed in once on this Mac.

## What you see

| Item | Meaning |
| --- | --- |
| Ring / tooltip | Display total % · included `$used/$limit` · slow-pool hint when active |
| Headline | “Included limit reached” when $ exhausted; otherwise Cursor’s % message |
| Included | Plan **$ used / $ limit** — reliable exhaustion signal |
| Pools | Auto · API · Total display % |
| On-demand | Pay-as-you-go, if enabled |
| Credits | Promo grants when present |
| Slow pool | Auto-only delay queue when active |
| Meta | Plan · billing cycle reset |

Cursor’s % fields can lag or disagree with dollars; the menu shows both.

### Refresh

| When | Interval |
| --- | --- |
| Menu opened in the last 5 min | 1 min |
| Idle | 5 min |
| Menu open / **Refresh** (`r`) | immediate |

## How it works

Reads `cursorAuth/accessToken` from local `state.vscdb` (read-only, no Keychain), then in parallel:

- `GET https://cursor.com/api/usage-summary`
- `POST …/GetUsageLimitStatusAndActiveGrants`

Undocumented dashboard APIs — not an official Cursor product. Token is never written back.

## Uninstall

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
```

## License

MIT

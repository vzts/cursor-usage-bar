<p align="center">
  <img src="assets/icon.png" width="96" alt="CursorUsageBar" />
</p>

<h1 align="center">CursorUsageBar</h1>

<p align="center">
  Cursor-Plan-Nutzung in der macOS-Menüleiste — Included-Dollar, Pool-%, Credits und Slow Pool.
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md"><b>Deutsch</b></a>
</p>

<p align="center">
  <img src="assets/hero.png" width="880" alt="CursorUsageBar-Vorschau" />
</p>

<p align="center">
  <img src="assets/menu-preview.png" width="560" alt="Menü-Vorschau" />
</p>

<p align="center">
  <code>./install.sh</code> — baut, installiert nach <code>~/Applications</code>, startet. Kein API-Key, kein Keychain.
</p>

---

## Installation

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

**Voraussetzungen:** macOS 14+, Xcode CLT / Swift 5.9+, Cursor IDE mindestens einmal auf diesem Mac angemeldet.

## Anzeige

| Element | Bedeutung |
| --- | --- |
| Ring / Tooltip | Anzeige-% · included `$verbraucht/$Limit` · Slow pool falls aktiv |
| Überschrift | „Included limit reached“, wenn $ leer; sonst Cursor-%-Text |
| Included | Plan-**$ verbraucht / $ Limit** — zuverlässiges Erschöpfungssignal |
| Pools | Auto · API · Total Anzeige-% |
| On-demand | Pay-as-you-go, falls aktiv |
| Credits | Promo-Grants, falls vorhanden |
| Slow pool | Auto-only-Warteschlange, falls aktiv |
| Meta | Plan · Zyklus-Reset |

In-App-% kann von den Dollar abweichen; beides wird gezeigt.

### Aktualisierung

| Wann | Intervall |
| --- | --- |
| Menü in den letzten 5 Min. geöffnet | 1 Min. |
| Idle | 5 Min. |
| Menü / **Refresh** (`r`) | sofort |

## Funktionsweise

Liest `cursorAuth/accessToken` aus lokaler `state.vscdb` (nur lesen, kein Keychain), parallel:

- `GET https://cursor.com/api/usage-summary`
- `POST …/GetUsageLimitStatusAndActiveGrants`

Inoffizielle Dashboard-API — kein offizielles Cursor-Produkt.

## Deinstallation

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
```

## Lizenz

MIT

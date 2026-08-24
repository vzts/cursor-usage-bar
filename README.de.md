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
  <img src="assets/hero.png" width="640" alt="CursorUsageBar-Vorschau" />
</p>

<p align="center">
  <code>./install.sh</code> — baut, installiert nach <code>~/Applications</code>, startet. Kein API-Key, kein Keychain.
</p>

---

## Warum

Cursor’s In-App-**% kann hinterherhinken** oder vom echten Included-**$ verbraucht/Limit** **abweichen**. CursorUsageBar zeigt beides in der Menüleiste — so siehst du, wann Included-Dollar wirklich leer sind und wann Credits oder Slow Pool greifen.

## Installation

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

Release-Build → WAL-safe Session-DB-Lesetest → Installation nach `~/Applications/CursorUsageBar.app` → Start.

**Voraussetzungen:** macOS 14+, Xcode CLT / Swift 5.9+, Cursor IDE mindestens einmal auf diesem Mac angemeldet (Token in lokaler `state.vscdb`; IDE muss nicht laufen).

## Anzeige

| Element | Bedeutung |
| --- | --- |
| Menüleisten-Tortendiagramm / Tooltip | Anzeige-% · included `$verbraucht/$Limit` · Slow pool falls aktiv |
| Überschrift | „Included limit reached“, wenn $ leer; sonst Cursor-%-Text |
| Included | `$verbraucht / $Limit` + `· exhausted` oder `· $X left` |
| Pools | Auto · API · Total Anzeige-% |
| On-demand | `$verbraucht / $Limit`, `$verbraucht used` oder `off` |
| Credits | `$Rest / $Gesamt · Ablauf` — ausgeblendet ohne Promo-Grants |
| Slow pool | Verzögerungs-Warteschlange — Auto only oder limited models · Grant $ · ~delay — ausgeblendet wenn inaktiv |
| Meta | z. B. `pro · resets Sep 17 (23d)` |

### Menüaktionen

| Aktion | |
| --- | --- |
| **Refresh** (`r`) | Neueste Nutzung abrufen |
| **Open Dashboard** (`o`) | [cursor.com/dashboard/spending](https://cursor.com/dashboard/spending) |
| **Quit** (`q`) | Beenden |

### Aktualisierung

| Wann | Intervall |
| --- | --- |
| Menü in den letzten 5 Min. geöffnet | 1 Min. |
| Idle | 5 Min. |
| Menü / **Refresh** (`r`) | sofort |

## Funktionsweise

1. Liest `cursorAuth/accessToken` aus  
   `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`  
   mit `mode=ro&immutable=1` — **kein Keychain**
2. Leitet Dashboard-Cookie aus JWT `sub` ab
3. **Parallel**:
   - `GET https://cursor.com/api/usage-summary` — Included $, Pool-%, On-demand, Plan/Zyklus
   - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants` — Credits + Slow pool
4. Credits / Slow pool **best-effort** — Hauptnutzung bleibt sichtbar, wenn Grants-RPC fehlschlägt

Inoffizielle Dashboard-API — **kein offizielles Cursor-Produkt**. Token wird bei jedem Refresh nur gelesen, nie geschrieben.

## Datenschutz

Im Repo stecken weder Token noch E-Mail noch Gerätepfade. Zur Laufzeit wird nur die lokale Cursor-Session auf **deinem** Mac gelesen.

## Deinstallation

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# Aus Anmeldeobjekten entfernen, falls hinzugefügt
```

## Lizenz

MIT

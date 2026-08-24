# CursorUsageBar

Minimal macOS menu bar app that shows your **Cursor** plan usage at a glance.

Menu bar shows a **16×16pt template usage ring** filled by Cursor’s display **total %** (`totalPercentUsed`). The menu also shows the **included $ used/limit** (the reliable exhaustion signal — Cursor’s % fields can lag or disagree with dollars).

## Requirements

- macOS 14+
- Cursor IDE signed in at least once on this Mac (token in local `state.vscdb`; IDE need not stay open)
- Xcode Command Line Tools / Swift 5.9+

## Install

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

This builds a release binary, verifies WAL-safe session DB reads, installs `~/Applications/CursorUsageBar.app`, then launches it.

## What you see

| UI | Meaning |
| --- | --- |
| Ring / tooltip | Display total % · included `$used/$limit` · slow-pool hint when active |
| Headline | “Included limit reached” when `$` remaining is 0; otherwise Cursor’s % message |
| Included | Plan included dollars used / limit (source of truth for hard exhaustion) |
| Pools | Auto · API · Total display percentages |
| On-demand | Pay-as-you-go bucket (if enabled) |
| Credits | Promo grants (`remaining / total` · expiry) when present |
| Slow pool | Auto-only delay queue + `usage_limit_policy` grant when active |
| Meta | Membership · billing cycle reset |

### Refresh cadence (adaptive)

| When | Interval |
| --- | --- |
| Menu opened in the last 5 minutes | every **1 minute** |
| Idle | every **5 minutes** |
| Menu open | immediate refresh |
| Manual | **Refresh** (`r`) |

This follows common menu-bar tracker practice: ClaudeBar’s **1-minute floor** while you’re looking, CursorBar’s **5-minute** idle poll for the same Cursor usage API, plus SessionWatcher-style refresh-on-open. Sub-minute polling rarely beats dashboard lag and wastes battery/network.

## How it works

1. Reads `cursorAuth/accessToken` from  
   `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`  
   (same approach as [CursorBar](https://github.com/c-johannesen/cursorbar) / MeterBar / ai-usagebar — **no Keychain prompt**)
2. Opens that SQLite DB with `mode=ro&immutable=1` so WAL sidecars are not required (IDE need not be running)
3. Derives the `WorkosCursorSessionToken` cookie from the JWT `sub`
4. In **parallel**:
   - `GET https://cursor.com/api/usage-summary` — included $, pool %, on-demand, plan/cycle
   - `POST …/GetUsageLimitStatusAndActiveGrants` — promo credits + slow-pool / `usage_limit_policy`

No API key is stored. The token is read fresh on each refresh and never written by this app.

There is **no official personal usage API**. Community trackers reverse the dashboard cookie / session JWT endpoints. Session JWTs typically last months; sudden failures are usually local DB open issues, not minute-by-minute expiry.

## Privacy

The published source does **not** contain your Cursor token, email, or machine paths. At runtime the app only reads the local Cursor session on **your** Mac. The MIT copyright line names the GitHub account that published the repo (normal for open source), not a secret.

## Privacy & caveats

- Uses Cursor’s **undocumented** dashboard API — it may change without notice.
- Needs a prior Cursor IDE login on this Mac (token lives in `state.vscdb`). Agent-only Keychain login is not used, to avoid macOS permission prompts.
- This is **not** an official Cursor product.

## Uninstall

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# Remove from Login Items if you added it
```

## License

MIT

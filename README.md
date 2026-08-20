# CursorUsageBar

Minimal macOS menu bar app that shows your **Cursor** plan usage at a glance.

Menu bar shows a **compact ring + `61%`** using Cursor’s **total included usage %** (`totalPercentUsed`) — the same idea as *“You've used X% of your included total usage”* — not the misleading `used/limit` counters some trackers treat as 100%.

## Requirements

- macOS 14+
- [Cursor](https://cursor.com) IDE signed in on this Mac (reads the local session)
- Xcode Command Line Tools / Swift 5.9+

## Install

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

This builds a release binary and installs `~/Applications/CursorUsageBar.app`, then launches it.

## What you see

| UI | Meaning |
| --- | --- |
| Compact ring + `61%` (single glyph, minimal pad) | Total included usage used this billing cycle |
| Auto / Composer | Included Auto + Composer pool |
| API / Other models | Included named/API model pool |
| On-demand | Pay-as-you-go bucket (if enabled) |
| Plan / Resets | Membership + billing cycle end |

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
2. Derives the `WorkosCursorSessionToken` cookie from the JWT `sub`
3. Calls `GET https://cursor.com/api/usage-summary`

No API key is stored. The token is read fresh on each refresh and never written by this app.

## Privacy

The published source does **not** contain your Cursor token, email, or machine paths. At runtime the app only reads the local Cursor IDE session on **your** Mac. The MIT copyright line names the GitHub account that published the repo (normal for open source), not a secret.

## Privacy & caveats

- Uses Cursor’s **undocumented** dashboard API — it may change without notice.
- You must be signed into the Cursor IDE on the same Mac.
- This is **not** an official Cursor product.

## Uninstall

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# Remove from Login Items if you added it
```

## License

MIT

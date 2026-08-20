# CursorUsageBar

Minimal macOS menu bar app that shows your **Cursor** plan usage at a glance.

Menu bar title uses Cursor’s **total included usage %** (`totalPercentUsed`) — the same idea as the dashboard message *“You've used X% of your included total usage”* — not the misleading `used/limit` counters some trackers treat as 100%.

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
| `C 61%` | Total included usage used this billing cycle |
| Auto / Composer | Included Auto + Composer pool |
| API / Other models | Included named/API model pool |
| On-demand | Pay-as-you-go bucket (if enabled) |
| Plan / Resets | Membership + billing cycle end |

Refresh every 5 minutes, or choose **Refresh** in the menu. **Open Dashboard** opens [cursor.com/dashboard](https://cursor.com/dashboard).

## How it works

1. Reads `cursorAuth/accessToken` from  
   `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`
2. Derives the `WorkosCursorSessionToken` cookie from the JWT `sub`
3. Calls `GET https://cursor.com/api/usage-summary`

No API key is stored. The token is read fresh on each refresh and never written by this app.

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

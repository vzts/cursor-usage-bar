<p align="center">
  <img src="assets/icon.png" width="96" alt="CursorUsageBar" />
</p>

<h1 align="center">CursorUsageBar</h1>

<p align="center">
  在 macOS 菜单栏查看 Cursor 套餐用量 — Included 美元、池 %、Credits、Slow pool。
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md"><b>简体中文</b></a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <img src="assets/hero.png" width="640" alt="CursorUsageBar 预览" />
</p>

<p align="center">
  <code>./install.sh</code> — 构建、安装到 <code>~/Applications</code>、启动。无需 API Key 或钥匙串弹窗。
</p>

---

## 为什么需要

Cursor 应用内的 **% 可能滞后**，或与真实的 Included **$ 已用/上限** **不一致**。CursorUsageBar 在菜单栏同时展示两者，便于判断 Included 美元是否真正用尽，以及 Credits、Slow pool 是否生效。

## 安装

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

构建发布版 → 验证 WAL-safe 会话 DB 读取 → 安装 `~/Applications/CursorUsageBar.app` → 启动。

**要求：** macOS 14+、Xcode CLT / Swift 5.9+、本机至少登录过一次 Cursor IDE（令牌在本地 `state.vscdb`，无需保持 IDE 运行）。

## 显示项

| 项目 | 含义 |
| --- | --- |
| 菜单栏饼图 / 提示 | 显示用 total % · included `$已用/$上限` · Slow pool（激活时） |
| 标题 | 美元耗尽时为 “Included limit reached”，否则为 Cursor 的 % 文案 |
| Included | `$已用 / $上限` + `· exhausted` 或 `· $X left` |
| Pools | Auto · API · Total 显示 % |
| On-demand | `$已用 / $上限`、`$已用 used` 或 `off` |
| Credits | `$剩余 / $总额 · 到期` — 无促销 grant 时隐藏 |
| Slow pool | 延迟队列 — Auto only 或 limited models · grant $ · ~delay — 未激活时隐藏 |
| Meta | 例：`pro · resets Sep 17 (23d)` |

### 菜单操作

| 操作 | |
| --- | --- |
| **Refresh** (`r`) | 获取最新用量 |
| **Open Dashboard** (`o`) | [cursor.com/dashboard/spending](https://cursor.com/dashboard/spending) |
| **Quit** (`q`) | 退出应用 |

### 刷新

| 场景 | 间隔 |
| --- | --- |
| 近 5 分钟内打开过菜单 | 1 分钟 |
| 空闲 | 5 分钟 |
| 打开菜单 / **Refresh**（`r`） | 立即 |

## 工作原理

1. 从 `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` 读取  
   `cursorAuth/accessToken`（`mode=ro&immutable=1` — **无钥匙串弹窗**）
2. 由 JWT `sub` 生成仪表盘 Cookie
3. **并行**请求：
   - `GET https://cursor.com/api/usage-summary` — Included $、池 %、on-demand、套餐/周期
   - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants` — Credits + Slow pool
4. Credits / Slow pool 为 **best-effort** — grants RPC 失败时仍显示主用量

非官方仪表盘 API — **非 Cursor 官方产品**。令牌每次 refresh 仅读取、不回写。

## 隐私

仓库不含 Cursor 令牌、邮箱或设备路径。运行时仅读取 **本机** 的本地 Cursor 会话。

## 卸载

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# 若已加入登录项，请一并移除
```

## 许可证

MIT

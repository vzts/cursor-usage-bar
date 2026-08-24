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
  <img src="assets/hero.png" width="880" alt="CursorUsageBar 预览" />
</p>

<p align="center">
  <img src="assets/menu-preview.png" width="560" alt="菜单预览" />
</p>

<p align="center">
  <code>./install.sh</code> — 构建、安装到 <code>~/Applications</code>、启动。无需 API Key 或钥匙串弹窗。
</p>

---

## 安装

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

**要求：** macOS 14+、Xcode CLT / Swift 5.9+、本机至少登录过一次 Cursor IDE。

## 显示项

| 项目 | 含义 |
| --- | --- |
| 圆环 / 提示 | 显示用 total % · included `$已用/$上限` · Slow pool（激活时） |
| 标题 | 美元耗尽时为 “Included limit reached”，否则为 Cursor 的 % 文案 |
| Included | 套餐 **$ 已用 / $ 上限** — 可靠的耗尽信号 |
| Pools | Auto · API · Total 显示 % |
| On-demand | 按量（若已开启） |
| Credits | 促销积分（若有） |
| Slow pool | 仅 Auto 延迟队列（若激活） |
| Meta | 套餐 · 账单周期重置 |

应用内 % 可能与美元不一致，因此同时展示两者。

### 刷新

| 场景 | 间隔 |
| --- | --- |
| 近 5 分钟内打开过菜单 | 1 分钟 |
| 空闲 | 5 分钟 |
| 打开菜单 / **Refresh**（`r`） | 立即 |

## 原理

从本地 `state.vscdb` 读取 `cursorAuth/accessToken`（只读，无钥匙串），并行请求:

- `GET https://cursor.com/api/usage-summary`
- `POST …/GetUsageLimitStatusAndActiveGrants`

非官方仪表盘 API — 非 Cursor 官方产品。

## 卸载

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
```

## 许可证

MIT

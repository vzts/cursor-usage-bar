<p align="center">
  <img src="assets/icon.png" width="96" alt="CursorUsageBar" />
</p>

<h1 align="center">CursorUsageBar</h1>

<p align="center">
  Cursor 플랜 사용량을 macOS 메뉴 바에서 — included 달러, 풀 %, Credits, Slow pool.
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md"><b>한국어</b></a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <img src="assets/hero.png" width="880" alt="CursorUsageBar 미리보기" />
</p>

<p align="center">
  <img src="assets/menu-preview.png" width="560" alt="메뉴 미리보기" />
</p>

<p align="center">
  <code>./install.sh</code> — 빌드, <code>~/Applications</code> 설치, 실행. API 키·Keychain 팝업 없음.
</p>

---

## 설치

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

**요구 사항:** macOS 14+, Xcode CLT / Swift 5.9+, 이 Mac에서 Cursor IDE에 한 번 이상 로그인.

## 표시 항목

| 항목 | 의미 |
| --- | --- |
| 링 / 툴팁 | 표시용 total % · included `$사용/$한도` · Slow pool(활성 시) |
| 헤드라인 | 달러 소진 시 “Included limit reached”, 아니면 Cursor % 메시지 |
| Included | 플랜 **$ 사용 / $ 한도** — 소진 판단의 기준 |
| Pools | Auto · API · Total 표시 % |
| On-demand | 종량제 (켜져 있을 때) |
| Credits | 프로모 크레딧 (있을 때만) |
| Slow pool | Auto 전용 지연 큐 (활성일 때만) |
| Meta | 플랜 · 빌링 사이클 리셋 |

Cursor 앱 %는 달러와 어긋나거나 늦게 갱신될 수 있어, 둘 다 보여 줍니다.

### 새로고침

| 상황 | 간격 |
| --- | --- |
| 최근 5분 안에 메뉴를 연 경우 | 1분 |
| 유휴 | 5분 |
| 메뉴 열기 / **Refresh** (`r`) | 즉시 |

## 동작 방식

로컬 `state.vscdb`에서 `cursorAuth/accessToken`을 읽고(읽기 전용, Keychain 없음), 병렬 호출:

- `GET https://cursor.com/api/usage-summary`
- `POST …/GetUsageLimitStatusAndActiveGrants`

비공식 대시보드 API — 공식 Cursor 제품이 아닙니다.

## 제거

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
```

## 라이선스

MIT

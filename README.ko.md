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
  <img src="assets/hero.png" width="380" alt="CursorUsageBar 미리보기" />
</p>

<p align="center">
  <code>./install.sh</code> — 빌드, <code>~/Applications</code> 설치, 실행. API 키·Keychain 팝업 없음.
</p>

---

## 왜 쓰나요

Cursor 앱 안 **%는 늦게 갱신되거나** 실제 included **$ 사용/한도**와 **어긋날 수** 있습니다. CursorUsageBar는 메뉴 바에서 둘 다 보여 주어, included 달러가 진짜로 소진됐는지 — Credits·Slow pool이 적용되는지 — 바로 알 수 있습니다.

## 설치

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

릴리스 빌드 → WAL-safe 세션 DB 읽기 검증 → `~/Applications/CursorUsageBar.app` 설치 → 실행.

**요구 사항:** macOS 14+, Xcode CLT / Swift 5.9+, 이 Mac에서 Cursor IDE에 한 번 이상 로그인 (토큰은 로컬 `state.vscdb`에 있음, IDE를 켜 둘 필요 없음).

## 표시 항목

| 항목 | 의미 |
| --- | --- |
| 메뉴 바 파이 / 툴팁 | 표시용 total % · included `$사용/$한도` · Slow pool(활성 시) |
| 헤드라인 | 달러 소진 시 “Included limit reached”, 아니면 Cursor % 메시지 |
| Included | `$사용 / $한도` + `· exhausted` 또는 `· $X left` |
| Pools | Auto · API · Total 표시 % |
| On-demand | `$사용 / $한도`, `$사용 used`, 또는 `off` |
| Credits | `$잔액 / $총액 · 만료` — 프로모 grant 없으면 숨김 |
| Slow pool | 지연 큐 — Auto only 또는 limited models · grant $ · ~delay — 비활성 시 숨김 |
| Meta | 예: `pro · resets Sep 17 (23d)` |

### 메뉴 액션

| 액션 | |
| --- | --- |
| **Refresh** (`r`) | 최신 사용량 가져오기 |
| **Open Dashboard** (`o`) | [cursor.com/dashboard/spending](https://cursor.com/dashboard/spending) |
| **Quit** (`q`) | 앱 종료 |

### 새로고침

| 상황 | 간격 |
| --- | --- |
| 최근 5분 안에 메뉴를 연 경우 | 1분 |
| 유휴 | 5분 |
| 메뉴 열기 / **Refresh** (`r`) | 즉시 |

## 동작 방식

1. `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`에서  
   `cursorAuth/accessToken` 읽기 (`mode=ro&immutable=1` — **Keychain 팝업 없음**)
2. JWT `sub`로 대시보드 세션 쿠키 구성
3. **병렬** 호출:
   - `GET https://cursor.com/api/usage-summary` — included $, 풀 %, on-demand, 플랜/사이클
   - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants` — Credits + Slow pool
4. Credits / Slow pool은 **best-effort** — grants RPC가 실패해도 기본 사용량은 표시

비공식 대시보드 API — **공식 Cursor 제품이 아닙니다**. 토큰은 매 refresh마다 읽기만 하고 쓰지 않습니다.

## 개인정보

저장소에 Cursor 토큰·이메일·기기 경로가 없습니다. 실행 시 **이 Mac**의 로컬 Cursor 세션만 읽습니다.

## 제거

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# 로그인 항목에 넣었다면 함께 제거
```

## 라이선스

MIT

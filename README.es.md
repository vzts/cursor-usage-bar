<p align="center">
  <img src="assets/icon.png" width="96" alt="CursorUsageBar" />
</p>

<h1 align="center">CursorUsageBar</h1>

<p align="center">
  Uso del plan Cursor en la barra de menús de macOS — dólares incluidos, % de pools, credits y slow pool.
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md"><b>Español</b></a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <img src="assets/hero.png" width="640" alt="Vista previa de CursorUsageBar" />
</p>

<p align="center">
  <code>./install.sh</code> — compila, instala en <code>~/Applications</code> y abre. Sin API key ni Keychain.
</p>

---

## Por qué

El **% en la app de Cursor puede retrasarse** o **no coincidir** con el real **$ usado/límite** incluido. CursorUsageBar muestra ambos en la barra de menús para ver cuándo se agotan los dólares incluidos y cuándo aplican credits o slow pool.

## Instalación

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

Compila release, verifica lectura WAL-safe de la DB de sesión, instala `~/Applications/CursorUsageBar.app` y la abre.

**Requisitos:** macOS 14+, Xcode CLT / Swift 5.9+, Cursor IDE iniciado al menos una vez en este Mac (token en `state.vscdb` local; el IDE no tiene que estar abierto).

## Qué muestra

| Elemento | Significado |
| --- | --- |
| Gráfico circular / tooltip | % total de visualización · included `$usado/$límite` · Slow pool si activo |
| Titular | “Included limit reached” si los $ se agotaron; si no, mensaje % de Cursor |
| Included | `$usado / $límite` + `· exhausted` o `· $X left` |
| Pools | % Auto · API · Total |
| On-demand | `$usado / $límite`, `$usado used` o `off` |
| Credits | `$restante / $total · caducidad` — oculto sin grants promo |
| Slow pool | Cola lenta — Auto only o limited models · grant $ · ~delay — oculto si inactivo |
| Meta | p. ej. `pro · resets Sep 17 (23d)` |

### Acciones del menú

| Acción | |
| --- | --- |
| **Refresh** (`r`) | Obtener uso actualizado |
| **Open Dashboard** (`o`) | [cursor.com/dashboard/spending](https://cursor.com/dashboard/spending) |
| **Quit** (`q`) | Salir |

### Actualización

| Cuándo | Intervalo |
| --- | --- |
| Menú abierto en los últimos 5 min | 1 min |
| Inactivo | 5 min |
| Abrir menú / **Refresh** (`r`) | inmediato |

## Cómo funciona

1. Lee `cursorAuth/accessToken` de  
   `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`  
   con `mode=ro&immutable=1` — **sin Keychain**
2. Deriva la cookie de sesión del JWT `sub`
3. En **paralelo**:
   - `GET https://cursor.com/api/usage-summary` — $ incluidos, % pools, on-demand, plan/ciclo
   - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants` — credits + slow pool
4. Credits / slow pool son **best-effort**: el uso principal sigue mostrándose si falla el RPC de grants

API no oficial del panel — **no es un producto oficial de Cursor**. El token se lee en cada refresh y nunca se escribe.

## Privacidad

El repositorio no contiene token, email ni rutas de máquina. En runtime solo lee la sesión local de Cursor en **tu** Mac.

## Desinstalar

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# Quita de Login Items si lo añadiste
```

## Licencia

MIT

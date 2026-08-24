<p align="center">
  <img src="assets/icon.png" width="96" alt="CursorUsageBar" />
</p>

<h1 align="center">CursorUsageBar</h1>

<p align="center">
  Usage du forfait Cursor dans la barre de menus macOS — dollars inclus, % des pools, credits et slow pool.
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md"><b>Français</b></a> ·
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <img src="assets/hero.png" width="880" alt="Aperçu CursorUsageBar" />
</p>

<p align="center">
  <img src="assets/menu-preview.png" width="560" alt="Aperçu du menu" />
</p>

<p align="center">
  <code>./install.sh</code> — compile, installe dans <code>~/Applications</code>, lance. Pas de clé API ni Keychain.
</p>

---

## Installation

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

**Prérequis :** macOS 14+, Xcode CLT / Swift 5.9+, Cursor IDE connecté au moins une fois sur ce Mac.

## Affichage

| Élément | Signification |
| --- | --- |
| Anneau / info-bulle | % total · included `$utilisé/$limite` · Slow pool si actif |
| Titre | « Included limit reached » si les $ sont épuisés ; sinon message % Cursor |
| Included | **$ utilisé / $ limite** — signal fiable d’épuisement |
| Pools | % Auto · API · Total |
| On-demand | À la demande, si activé |
| Credits | Crédits promo, le cas échéant |
| Slow pool | File Auto uniquement, si active |
| Meta | Forfait · fin de cycle |

Le % in-app peut diverger des dollars ; les deux sont affichés.

### Rafraîchissement

| Quand | Intervalle |
| --- | --- |
| Menu ouvert dans les 5 dernières min | 1 min |
| Inactif | 5 min |
| Ouvrir menu / **Refresh** (`r`) | immédiat |

## Fonctionnement

Lit `cursorAuth/accessToken` dans `state.vscdb` local (lecture seule, sans Keychain), puis en parallèle :

- `GET https://cursor.com/api/usage-summary`
- `POST …/GetUsageLimitStatusAndActiveGrants`

API tableau de bord non officielle — produit Cursor non officiel.

## Désinstallation

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
```

## Licence

MIT

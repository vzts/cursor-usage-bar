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
  <img src="assets/hero.png" width="720" alt="Aperçu CursorUsageBar" />
</p>

<p align="center">
  <code>./install.sh</code> — compile, installe dans <code>~/Applications</code>, lance. Pas de clé API ni Keychain.
</p>

---

## Pourquoi

Le **% in-app de Cursor peut être en retard** ou **ne pas correspondre** au vrai **$ utilisé/limite** inclus. CursorUsageBar affiche les deux dans la barre de menus pour voir quand les dollars inclus sont épuisés et quand credits ou slow pool s’appliquent.

## Installation

```bash
git clone https://github.com/vzts/cursor-usage-bar.git
cd cursor-usage-bar
./install.sh
```

Compile en release, vérifie la lecture WAL-safe de la DB de session, installe `~/Applications/CursorUsageBar.app` et lance l’app.

**Prérequis :** macOS 14+, Xcode CLT / Swift 5.9+, Cursor IDE connecté au moins une fois sur ce Mac (jeton dans `state.vscdb` local ; l’IDE n’a pas besoin de rester ouvert).

## Affichage

| Élément | Signification |
| --- | --- |
| Camembert / info-bulle | % total d’affichage · included `$utilisé/$limite` · Slow pool si actif |
| Titre | « Included limit reached » si les $ sont épuisés ; sinon message % Cursor |
| Included | `$utilisé / $limite` + `· exhausted` ou `· $X left` |
| Pools | % Auto · API · Total |
| On-demand | `$utilisé / $limite`, `$utilisé used` ou `off` |
| Credits | `$reste / $total · expiration` — masqué sans grants promo |
| Slow pool | File lente — Auto only ou limited models · grant $ · ~delay — masqué si inactif |
| Meta | ex. `pro · resets Sep 17 (23d)` |

### Actions du menu

| Action | |
| --- | --- |
| **Refresh** (`r`) | Récupérer l’usage à jour |
| **Open Dashboard** (`o`) | [cursor.com/dashboard/spending](https://cursor.com/dashboard/spending) |
| **Quit** (`q`) | Quitter |

### Rafraîchissement

| Quand | Intervalle |
| --- | --- |
| Menu ouvert dans les 5 dernières min | 1 min |
| Inactif | 5 min |
| Ouvrir menu / **Refresh** (`r`) | immédiat |

## Fonctionnement

1. Lit `cursorAuth/accessToken` dans  
   `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`  
   avec `mode=ro&immutable=1` — **sans Keychain**
2. Dérive le cookie de session à partir du JWT `sub`
3. En **parallèle** :
   - `GET https://cursor.com/api/usage-summary` — $ inclus, % pools, on-demand, forfait/cycle
   - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetUsageLimitStatusAndActiveGrants` — credits + slow pool
4. Credits / slow pool en **best-effort** : l’usage principal reste affiché si le RPC grants échoue

API tableau de bord non officielle — **produit Cursor non officiel**. Le jeton est lu à chaque refresh et jamais écrit.

## Confidentialité

Le dépôt ne contient pas de jeton, e-mail ou chemins machine. Au runtime, seule la session Cursor locale sur **votre** Mac est lue.

## Désinstallation

```bash
killall CursorUsageBar 2>/dev/null || true
rm -rf ~/Applications/CursorUsageBar.app
# Retirez des éléments de connexion si ajouté
```

## Licence

MIT

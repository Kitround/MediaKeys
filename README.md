# MediaKeys

Petite app macOS qui vit dans la barre de menu et redirige les touches média du clavier (Play/Pause, Suivant, Précédent) vers **Spotify**, **Apple Music**, ou les deux — sans latence, et avec un routage intelligent quand les deux apps tournent.

> Pourquoi ? Parce que macOS envoie par défaut les touches média à l'app qui a décidé de les prendre en premier (souvent Apple Music, même quand on écoute Spotify). MediaKeys reprend la main et choisit la bonne cible.

---

## Fonctionnalités

- 🎛️ **Routage configurable** : Spotify uniquement, Apple Music uniquement, ou les deux.
- 🧠 **Mode intelligent** (`Spotify + Apple Music`) : la commande va à l'app qui joue effectivement, déterminé en temps réel.
- ⚡ **Zéro latence** : l'état de lecture est suivi passivement via les notifications distribuées émises par Spotify et Apple Music, donc aucun appel AppleScript bloquant au moment du clic.
- 🧊 **Discret** : vit dans la barre de menu (`LSUIElement`), aucune fenêtre, aucun dock icon.
- ⏸️ **Pause globale** : un clic pour suspendre l'interception et laisser le système gérer les touches média.

---

## Captures

L'icône `♪` apparaît dans la barre de menu. Le menu propose le mode de redirection et la pause globale.

---

## Installation

### Pré-requis

- macOS 13 (Ventura) ou plus récent
- Xcode 14+

### Compilation

```bash
git clone https://github.com/Kitround/MediaKeys.git
cd MediaKeys
open MediaKeys.xcodeproj
```

Puis dans Xcode : **Product → Run** (⌘R).

### Première utilisation

Au premier lancement, macOS demandera l'autorisation **Accessibilité** — c'est nécessaire pour intercepter les événements clavier système. Va dans **Réglages Système → Confidentialité et sécurité → Accessibilité** et active MediaKeys.

---

## Architecture

| Fichier | Rôle |
|---|---|
| [`AppDelegate.swift`](MediaKeys/AppDelegate.swift) | Point d'entrée, cycle de vie |
| [`EventTapManager.swift`](MediaKeys/EventTapManager.swift) | Capture clavier via `CGEvent.tapCreate` |
| [`MediaCommandSender.swift`](MediaKeys/MediaCommandSender.swift) | Routage + envoi des commandes via `osascript` |
| [`PreferencesManager.swift`](MediaKeys/PreferencesManager.swift) | Persistance (`UserDefaults`) |
| [`StatusMenuController.swift`](MediaKeys/StatusMenuController.swift) | UI barre de menu |

### Décisions techniques

- **Pas d'`osascript` pour lire l'état** — trop lent (~200 ms par appel). À la place, `PlaybackStateCache` écoute en continu :
  - `com.spotify.client.PlaybackStateChanged`
  - `com.apple.Music.playerInfo`
- **`osascript` uniquement pour envoyer** les commandes (`playpause`, `next track`, `previous track` / `back track`).
- **Event tap** de type `.cgSessionEventTap` en `.headInsertEventTap` ; consomme les key-down média, laisse passer le reste (volume, etc.).

### Routage en mode `both`

- **Play/Pause** : si une seule app joue → elle reçoit ; si les deux jouent → les deux reçoivent ; sinon → reprise sur `lastPlayingApp` (Spotify par défaut).
- **Suivant / Précédent** : envoyé uniquement aux apps actuellement en lecture.

---

## Permissions

L'app demande :
- **Accessibilité** : obligatoire (event tap système).
- **Apple Events** vers Spotify & Music : pour envoyer les commandes via `osascript`.

L'entitlement `com.apple.security.automation.apple-events` est défini dans [`MediaKeys.entitlements`](MediaKeys/MediaKeys.entitlements).

---

## Licence

MIT — voir [LICENSE](LICENSE).

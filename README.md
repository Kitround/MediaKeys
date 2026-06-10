# MediaKeys

Tiny macOS menu bar app that routes the keyboard media keys (Play/Pause, Next, Previous) to **Spotify**, **Apple Music**, or both — with zero latency and smart routing when both apps are running.

> Available in **English** and **French** (auto-detected from your system language).

> Why? macOS sends media keys to whichever app grabbed them first (often Apple Music, even when you're listening to Spotify). MediaKeys takes over and picks the right target.

---

## Features

- 🎛️ **Configurable routing**: Spotify only, Apple Music only, or both.
- 🧠 **Smart mode** (`Spotify + Apple Music`): commands go to the app that's actually playing, decided in real time.
- ⚡ **Zero latency**: playback state is tracked passively via the distributed notifications Spotify and Apple Music broadcast — no blocking AppleScript call at click time.
- 🧊 **Discreet**: lives in the menu bar (`LSUIElement`), no window, no dock icon.
- ⏸️ **Global pause**: one click to suspend interception and let the system handle media keys.
- 🌐 **Localized**: English (default) and French.

---

## Screenshots

A `♪` icon appears in the menu bar. The menu offers the redirect mode and global pause.

---

## Installation

### Requirements

- macOS 13 (Ventura) or newer

### Download

Grab the latest `MediaKeys.zip` from the [Releases page](https://github.com/Kitround/MediaKeys/releases), unzip it, and drag **MediaKeys.app** into `/Applications`.

### First launch

On first launch macOS will prompt for **Accessibility** permission — required to intercept system keyboard events. Go to **System Settings → Privacy & Security → Accessibility** and enable MediaKeys.

---

## Architecture

| File | Role |
|---|---|
| [`AppDelegate.swift`](MediaKeys/AppDelegate.swift) | Entry point, lifecycle |
| [`EventTapManager.swift`](MediaKeys/EventTapManager.swift) | Keyboard capture via `CGEvent.tapCreate` |
| [`MediaCommandSender.swift`](MediaKeys/MediaCommandSender.swift) | Routing + command dispatch via `osascript` |
| [`PreferencesManager.swift`](MediaKeys/PreferencesManager.swift) | Persistence (`UserDefaults`) |
| [`StatusMenuController.swift`](MediaKeys/StatusMenuController.swift) | Menu bar UI |
| [`Localizable.xcstrings`](MediaKeys/Localizable.xcstrings) | UI strings (en + fr) |
| [`InfoPlist.xcstrings`](MediaKeys/InfoPlist.xcstrings) | Info.plist strings (en + fr) |

### Technical decisions

- **No `osascript` to read state** — too slow (~200 ms per call). Instead, `PlaybackStateCache` listens continuously to:
  - `com.spotify.client.PlaybackStateChanged`
  - `com.apple.Music.playerInfo`
- **`osascript` only to send** commands (`playpause`, `next track`, `previous track` / `back track`).
- **Event tap** of type `.cgSessionEventTap` at `.headInsertEventTap`; consumes media key-downs, passes everything else through (volume, etc.).

### `both` mode routing

- **Play/Pause**: if a single app is playing → it receives; if both play → both receive; otherwise → resume on `lastPlayingApp` (Spotify by default).
- **Next / Previous**: sent only to apps currently playing.

---

## Localization

UI strings live in [`Localizable.xcstrings`](MediaKeys/Localizable.xcstrings) (String Catalog). System permission strings live in [`InfoPlist.xcstrings`](MediaKeys/InfoPlist.xcstrings). English is the source language; French is provided. Adding a new language is just adding a column in Xcode's String Catalog editor.

---

## Permissions

The app requests:
- **Accessibility**: required (system event tap).
- **Apple Events** to Spotify & Music: to send commands via `osascript`.

The `com.apple.security.automation.apple-events` entitlement is set in [`MediaKeys.entitlements`](MediaKeys/MediaKeys.entitlements).

---

## License

MIT — see [LICENSE](LICENSE).

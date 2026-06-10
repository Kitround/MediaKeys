import Cocoa

enum TargetApp: String, CaseIterable {
    case spotify = "Spotify"
    case music   = "Music"
}

// MARK: - Playback state cache updated passively by app notifications

/// Spotify and Apple Music broadcast their state in real time via DistributedNotificationCenter.
/// We listen to those notifications to keep an always-up-to-date cache — no osascript call
/// at click time, hence zero latency.
final class PlaybackStateCache {
    static let shared = PlaybackStateCache()

    private(set) var spotifyPlaying = false
    private(set) var musicPlaying   = false

    private init() {
        let dnc = DistributedNotificationCenter.default()

        // Spotify: "com.spotify.client.PlaybackStateChanged"
        // userInfo["Player State"] == "Playing" | "Paused" | "Stopped"
        dnc.addObserver(
            self,
            selector: #selector(onSpotify(_:)),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )

        // Apple Music: "com.apple.Music.playerInfo"
        // userInfo["Player State"] == "Playing" | "Paused" | "Stopped"
        dnc.addObserver(
            self,
            selector: #selector(onMusic(_:)),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    @objc private func onSpotify(_ note: Notification) {
        spotifyPlaying = (note.userInfo?["Player State"] as? String) == "Playing"
        print("🎵 Spotify → playing=\(spotifyPlaying)")
    }

    @objc private func onMusic(_ note: Notification) {
        musicPlaying = (note.userInfo?["Player State"] as? String) == "Playing"
        print("🎵 Music → playing=\(musicPlaying)")
    }
}

// MARK: -

struct MediaCommandSender {

    static func send(key: MediaKey) {
        let mode = PreferencesManager.shared.targetMode

        switch key {
        case .playPause:
            sendPlayPause(mode: mode)
        default:
            sendNavigationKey(key, mode: mode)
        }
    }

    // MARK: - Navigation

    private static func sendNavigationKey(_ key: MediaKey, mode: TargetMode) {
        guard mode == .both else {
            if let target = mode.apps.first {
                runOsascript(script(for: key, target: target))
            }
            return
        }

        let cache = PlaybackStateCache.shared
        if cache.spotifyPlaying { runOsascript(script(for: key, target: .spotify)) }
        if cache.musicPlaying   { runOsascript(script(for: key, target: .music)) }
        if !cache.spotifyPlaying && !cache.musicPlaying {
            print("⏭ navigation ignored: no app currently playing")
        }
    }

    // MARK: - Play/Pause

    private static func sendPlayPause(mode: TargetMode) {
        guard mode == .both else {
            if let target = mode.apps.first {
                runOsascript(script(for: .playPause, target: target))
            }
            return
        }

        let cache = PlaybackStateCache.shared
        let spotifyPlaying = cache.spotifyPlaying
        let musicPlaying   = cache.musicPlaying

        print("▶️ spotify=\(spotifyPlaying) music=\(musicPlaying)")

        if spotifyPlaying && musicPlaying {
            runOsascript(script(for: .playPause, target: .spotify))
            runOsascript(script(for: .playPause, target: .music))

        } else if spotifyPlaying {
            PreferencesManager.shared.lastPlayingApp = .spotify
            runOsascript(script(for: .playPause, target: .spotify))

        } else if musicPlaying {
            PreferencesManager.shared.lastPlayingApp = .music
            runOsascript(script(for: .playPause, target: .music))

        } else {
            if let last = PreferencesManager.shared.lastPlayingApp {
                runOsascript(script(for: .playPause, target: last))
            } else {
                runOsascript(script(for: .playPause, target: .spotify))
            }
        }
    }

    // MARK: - Script builder

    private static func script(for key: MediaKey, target: TargetApp) -> String {
        let app: String
        let command: String

        switch target {
        case .spotify:
            app = "Spotify"
            switch key {
            case .playPause:          command = "playpause"
            case .next, .fastForward: command = "next track"
            case .previous, .rewind:  command = "previous track"
            }
        case .music:
            app = "Music"
            switch key {
            case .playPause:          command = "playpause"
            case .next, .fastForward: command = "next track"
            case .previous, .rewind:  command = "back track"
            }
        }

        return "tell application \"\(app)\" to \(command)"
    }

    // MARK: - Runner

    private static func runOsascript(_ source: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", source]

            let pipe = Pipe()
            task.standardError  = pipe
            task.standardOutput = pipe

            task.launch()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    print("⚠️ osascript error: \(output)")
                }
            }
        }
    }
}

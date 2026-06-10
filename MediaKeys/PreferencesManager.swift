import Foundation

enum TargetMode: String {
    case spotify = "spotify"
    case music   = "music"
    case both    = "both"

    var displayName: String {
        switch self {
        case .spotify: return String(localized: "Spotify", comment: "Target mode: Spotify only")
        case .music:   return String(localized: "Apple Music", comment: "Target mode: Apple Music only")
        case .both:    return String(localized: "Spotify + Apple Music", comment: "Target mode: both apps")
        }
    }

    var apps: [TargetApp] {
        switch self {
        case .spotify: return [.spotify]
        case .music:   return [.music]
        case .both:    return [.spotify, .music]
        }
    }
}

class PreferencesManager {

    static let shared = PreferencesManager()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let targetMode     = "targetMode"
        static let isPaused       = "isPaused"
        static let lastPlayingApp = "lastPlayingApp"
    }

    var targetMode: TargetMode {
        get {
            let raw = defaults.string(forKey: Keys.targetMode) ?? TargetMode.spotify.rawValue
            return TargetMode(rawValue: raw) ?? .spotify
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.targetMode) }
    }

    var lastPlayingApp: TargetApp? {
        get {
            guard let raw = defaults.string(forKey: Keys.lastPlayingApp) else { return nil }
            return TargetApp(rawValue: raw)
        }
        set { defaults.set(newValue?.rawValue, forKey: Keys.lastPlayingApp) }
    }

    var isPaused: Bool {
        get { defaults.bool(forKey: Keys.isPaused) }
        set { defaults.set(newValue, forKey: Keys.isPaused) }
    }
}

import Cocoa
import Carbon

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusMenuController: StatusMenuController!
    var eventTapManager: EventTapManager!

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)

        _ = PlaybackStateCache.shared  // start listening to Spotify & Music notifications

        statusMenuController = StatusMenuController()

        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        )
        print("🚀 trusted: \(trusted)")

        if trusted {
            startEventTap()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.startEventTap()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        eventTapManager?.stop()
    }

    private func startEventTap() {
        print("🚀 startEventTap")
        eventTapManager = EventTapManager()
        eventTapManager.onMediaKey = { [weak self] key in
            self?.handleMediaKey(key)
        }
        eventTapManager.start()
    }

    private func handleMediaKey(_ key: MediaKey) {
        guard !PreferencesManager.shared.isPaused else { return }
        MediaCommandSender.send(key: key)
    }
}

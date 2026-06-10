import Cocoa

class StatusMenuController: NSObject {

    var statusItem: NSStatusItem!

    override init() {
        super.init()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "MediaKeys") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "♪"
            }
        }

        statusItem.menu = buildMenu()
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let prefs = PreferencesManager.shared

        let title = NSMenuItem(
            title: String(localized: "Redirect to:", comment: "Menu section header"),
            action: nil,
            keyEquivalent: ""
        )
        title.isEnabled = false
        menu.addItem(title)

        for mode in [TargetMode.spotify, .music, .both] {
            let item = NSMenuItem(title: mode.displayName, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = prefs.targetMode == mode ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let pauseTitle = prefs.isPaused
            ? String(localized: "Resume", comment: "Resume interception menu item")
            : String(localized: "Pause", comment: "Pause interception menu item")
        let pause = NSMenuItem(title: pauseTitle, action: #selector(togglePause), keyEquivalent: "p")
        pause.target = self
        menu.addItem(pause)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: String(localized: "Quit MediaKeys", comment: "Quit menu item"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        return menu
    }

    @objc func selectMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = TargetMode(rawValue: raw) else { return }
        PreferencesManager.shared.targetMode = mode
        statusItem.menu = buildMenu()
    }

    @objc func togglePause() {
        PreferencesManager.shared.isPaused.toggle()
        let symbolName = PreferencesManager.shared.isPaused ? "music.note.slash" : "music.note"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "MediaKeys") {
            image.isTemplate = true
            statusItem.button?.image = image
        }
        statusItem.menu = buildMenu()
    }
}

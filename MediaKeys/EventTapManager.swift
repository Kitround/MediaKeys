import Cocoa
import Carbon

let NX_KEYTYPE_PLAY: Int32     = 16
let NX_KEYTYPE_NEXT: Int32     = 17
let NX_KEYTYPE_PREVIOUS: Int32 = 18
let NX_KEYTYPE_FAST: Int32     = 19
let NX_KEYTYPE_REWIND: Int32   = 20

enum MediaKey {
    case playPause
    case next
    case previous
    case fastForward
    case rewind
}

class EventTapManager {

    var onMediaKey: ((MediaKey) -> Void)?
    var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        print("EventTapManager start")
        let eventMask = CGEventMask(1 << NX_SYSDEFINED)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                if type == .tapDisabledByTimeout {
                    if let tap = manager.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passRetained(event)
                }
                return manager.handle(event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = eventTap else {
            print("Event tap failed")
            showAccessibilityAlert()
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("Event tap started")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    func handle(event: CGEvent) -> Unmanaged<CGEvent>? {
        guard let nsEvent = NSEvent(cgEvent: event),
              nsEvent.type == .systemDefined,
              nsEvent.subtype.rawValue == 8 else {
            return Unmanaged.passRetained(event)
        }

        let data1     = nsEvent.data1
        let keyCode   = Int32((data1 & 0xFFFF0000) >> 16)
        let keyFlags  = data1 & 0x0000FFFF
        let isKeyDown = ((keyFlags & 0xFF00) >> 8) == 0xA

        var mediaKey: MediaKey?

        switch keyCode {
        case NX_KEYTYPE_PLAY:
            mediaKey = .playPause
        case NX_KEYTYPE_NEXT:
            mediaKey = .next
        case NX_KEYTYPE_PREVIOUS:
            mediaKey = .previous
        case NX_KEYTYPE_FAST:
            mediaKey = .fastForward
        case NX_KEYTYPE_REWIND:
            mediaKey = .rewind
        default:
            // Unhandled key (volume, etc.) → pass through
            return Unmanaged.passRetained(event)
        }

        // Recognized media key: consume key-down, pass through key-up
        if isKeyDown, let key = mediaKey {
            DispatchQueue.main.async { self.onMediaKey?(key) }
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Permission required", comment: "Accessibility permission alert title")
        alert.informativeText = String(
            localized: "MediaKeys needs Accessibility access.\n\nOpen System Settings → Privacy & Security → Accessibility and add MediaKeys.",
            comment: "Accessibility permission alert body"
        )
        alert.addButton(withTitle: String(localized: "Open Settings", comment: "Open System Settings button"))
        alert.addButton(withTitle: String(localized: "Cancel", comment: "Cancel button"))
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}

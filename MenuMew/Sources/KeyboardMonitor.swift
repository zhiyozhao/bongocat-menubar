import AppKit
import CoreGraphics

class KeyboardMonitor {
    var onKeyDown: ((UInt16) -> Void)?
    var onKeyUp: ((UInt16) -> Void)?
    var isRunning: Bool { eventTap != nil }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (_, type, event, userInfo) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
                let keycode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                DispatchQueue.main.async {
                    if type == .keyDown {
                        monitor.onKeyDown?(keycode)
                    } else if type == .keyUp {
                        monitor.onKeyUp?(keycode)
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard eventTap != nil else { return }

        if let tap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }

    deinit { stop() }
}

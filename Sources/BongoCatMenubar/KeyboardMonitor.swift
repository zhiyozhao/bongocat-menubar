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

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (_, type, event, userInfo) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo!).takeUnretainedValue()

                // System disabled our tap (permission revoked or timeout) → re-enable
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = monitor.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                let keycode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                DispatchQueue.main.async {
                    if type == .keyDown {
                        monitor.onKeyDown?(keycode)
                    } else if type == .keyUp {
                        monitor.onKeyUp?(keycode)
                    } else if type == .flagsChanged {
                        let isDown = modifierKeyIsDown(keycode: keycode, flags: event.flags)
                        if isDown {
                            monitor.onKeyDown?(keycode)
                        } else {
                            monitor.onKeyUp?(keycode)
                        }
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

private func modifierKeyIsDown(keycode: UInt16, flags: CGEventFlags) -> Bool {
    let mask: CGEventFlags
    switch keycode {
    case 59, 62: mask = .maskControl     // LCtrl, RCtrl
    case 58, 61: mask = .maskAlternate   // LOpt, ROpt
    case 55, 54: mask = .maskCommand     // LCmd, RCmd
    case 56, 60: mask = .maskShift       // LShift, RShift
    default:      return false
    }
    return flags.contains(mask)
}

import CoreGraphics

// Device-dependent modifier bits (IOKit NX_DEVICE*KEYMASK). They tell the left and
// right copy of a modifier apart; the generic CGEventFlags masks do not.
private let deviceLCtrl: UInt64 = 0x0000_0001
private let deviceLShift: UInt64 = 0x0000_0002
private let deviceRShift: UInt64 = 0x0000_0004
private let deviceLCmd: UInt64 = 0x0000_0008
private let deviceRCmd: UInt64 = 0x0000_0010
private let deviceLAlt: UInt64 = 0x0000_0020
private let deviceRAlt: UInt64 = 0x0000_0040
private let deviceRCtrl: UInt64 = 0x0000_2000

/// For a `flagsChanged` event, decide whether the modifier `keycode` was pressed
/// (`true`) or released (`false`). Non-modifier keycodes return `false`.
///
/// Uses the per-side device bit so that releasing Left Shift while Right Shift is
/// still held reports Left Shift as released. Falls back to the generic mask when
/// the event carries no device bits for that modifier (e.g. synthetic events).
public func modifierKeyIsDown(keycode: UInt16, flags: CGEventFlags) -> Bool {
    let generic: CGEventFlags
    let own: UInt64
    let other: UInt64
    switch keycode {
    case 59: (generic, own, other) = (.maskControl, deviceLCtrl, deviceRCtrl)     // LCtrl
    case 62: (generic, own, other) = (.maskControl, deviceRCtrl, deviceLCtrl)     // RCtrl
    case 58: (generic, own, other) = (.maskAlternate, deviceLAlt, deviceRAlt)     // LOpt
    case 61: (generic, own, other) = (.maskAlternate, deviceRAlt, deviceLAlt)     // ROpt
    case 55: (generic, own, other) = (.maskCommand, deviceLCmd, deviceRCmd)       // LCmd
    case 54: (generic, own, other) = (.maskCommand, deviceRCmd, deviceLCmd)       // RCmd
    case 56: (generic, own, other) = (.maskShift, deviceLShift, deviceRShift)     // LShift
    case 60: (generic, own, other) = (.maskShift, deviceRShift, deviceLShift)     // RShift
    default: return false
    }
    let raw = flags.rawValue
    if raw & (own | other) == 0 {
        return flags.contains(generic)
    }
    return raw & own != 0
}

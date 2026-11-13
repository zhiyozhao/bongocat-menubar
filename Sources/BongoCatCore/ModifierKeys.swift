import CoreGraphics

/// For a `flagsChanged` event, decide whether the modifier `keycode` was pressed
/// (`true`) or released (`false`). Non-modifier keycodes return `false`.
public func modifierKeyIsDown(keycode: UInt16, flags: CGEventFlags) -> Bool {
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

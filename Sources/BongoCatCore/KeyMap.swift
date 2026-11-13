/// Which hand a macOS virtual keycode belongs to (QWERTY ANSI layout).
public enum Hand: Equatable, Sendable {
    case left
    case right
}

public enum KeyMap {
    // Left-hand keycodes (QWERTY standard macOS)
    public static let leftKeycodes: Set<UInt16> = [
        // Row 1 (Esc + F keys):  Esc F1 F2 F3 F4 F5
        53, 122, 120, 99, 118, 96,
        // Row 2 (numbers):        ` 1 2 3 4 5
        50, 18, 19, 20, 21, 23,
        // Row 3 (QWERTY):         Tab Q W E R T
        48, 12, 13, 14, 15, 17,
        // Row 4 (home row):       Caps A S D F G
        57, 0, 1, 2, 3, 5,
        // Row 5 (bottom):         LShift Z X C V B
        56, 6, 7, 8, 9, 11,
        // Row 6 (modifiers):      LCtrl LOpt LCmd
        59, 58, 55,
    ]

    public static let rightKeycodes: Set<UInt16> = [
        // Row 1 (F keys):         F6 F7 F8 F9 F10 F11 F12
        97, 98, 100, 101, 109, 103, 111,
        // Row 2 (numbers):        6 7 8 9 0 - = Backspace
        22, 26, 28, 25, 29, 27, 24, 51,
        // Row 3 (QWERTY):         Y U I O P [ ] backslash
        16, 32, 34, 31, 35, 33, 30, 42,
        // Row 4 (home row):       H J K L ; ' Enter
        4, 38, 40, 37, 41, 39, 36,
        // Row 5 (bottom):         N M , . / RShift
        45, 46, 43, 47, 44, 60,
        // Row 6 (modifiers):      Space RCmd ROpt RCtrl
        49, 54, 61, 62,
        // Arrow keys:             ← → ↑ ↓
        123, 124, 125, 126,
    ]

    /// The hand for `keycode`, or `nil` if the key is not animated.
    public static func hand(for keycode: UInt16) -> Hand? {
        if leftKeycodes.contains(keycode) { return .left }
        if rightKeycodes.contains(keycode) { return .right }
        return nil
    }
}

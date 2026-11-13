import Testing
@testable import BongoCatCore

@Suite("KeyMap: left/right hand split")
struct KeyMapTests {
    // macOS virtual keycodes (Carbon kVK_ANSI_*)
    static let leftLetters: [UInt16] = [12, 13, 14, 15, 17, 0, 1, 2, 3, 5, 6, 7, 8, 9, 11] // QWERT ASDFG ZXCVB
    static let rightLetters: [UInt16] = [16, 32, 34, 31, 35, 4, 38, 40, 37, 45, 46]        // YUIOP HJKL NM

    @Test("left-hand letters", arguments: leftLetters)
    func leftLetter(keycode: UInt16) {
        #expect(KeyMap.hand(for: keycode) == .left)
    }

    @Test("right-hand letters", arguments: rightLetters)
    func rightLetter(keycode: UInt16) {
        #expect(KeyMap.hand(for: keycode) == .right)
    }

    @Test("modifiers split by side")
    func modifiers() {
        #expect(KeyMap.hand(for: 56) == .left)   // LShift
        #expect(KeyMap.hand(for: 59) == .left)   // LCtrl
        #expect(KeyMap.hand(for: 58) == .left)   // LOpt
        #expect(KeyMap.hand(for: 55) == .left)   // LCmd
        #expect(KeyMap.hand(for: 60) == .right)  // RShift
        #expect(KeyMap.hand(for: 62) == .right)  // RCtrl
        #expect(KeyMap.hand(for: 61) == .right)  // ROpt
        #expect(KeyMap.hand(for: 54) == .right)  // RCmd
    }

    @Test("space, enter, backspace and arrows are right hand")
    func rightSideSpecials() {
        for keycode: UInt16 in [49, 36, 51, 123, 124, 125, 126] {
            #expect(KeyMap.hand(for: keycode) == .right, "keycode \(keycode)")
        }
    }

    @Test("Esc, Tab, backtick and F1–F5 are left hand; F6–F12 right")
    func functionRow() {
        for keycode: UInt16 in [53, 48, 50, 122, 120, 99, 118, 96] {
            #expect(KeyMap.hand(for: keycode) == .left, "keycode \(keycode)")
        }
        for keycode: UInt16 in [97, 98, 100, 101, 109, 103, 111] {
            #expect(KeyMap.hand(for: keycode) == .right, "keycode \(keycode)")
        }
    }

    @Test("keys outside the map are ignored (keypad, fn, forward delete)")
    func unmapped() {
        for keycode: UInt16 in [82, 83, 69, 76, 63, 117] {
            #expect(KeyMap.hand(for: keycode) == nil, "keycode \(keycode)")
        }
    }

    @Test("no keycode belongs to both hands")
    func disjoint() {
        #expect(KeyMap.leftKeycodes.isDisjoint(with: KeyMap.rightKeycodes))
    }
}

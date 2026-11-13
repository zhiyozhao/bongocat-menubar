import CoreGraphics
import Testing
@testable import BongoCatCore

@Suite("Modifier flagsChanged → down/up")
struct ModifierKeysTests {
    @Test("modifier pressed when its flag is set")
    func pressed() {
        #expect(modifierKeyIsDown(keycode: 56, flags: .maskShift))      // LShift
        #expect(modifierKeyIsDown(keycode: 59, flags: .maskControl))    // LCtrl
        #expect(modifierKeyIsDown(keycode: 58, flags: .maskAlternate))  // LOpt
        #expect(modifierKeyIsDown(keycode: 55, flags: .maskCommand))    // LCmd
    }

    @Test("modifier released when its flag is cleared")
    func released() {
        #expect(!modifierKeyIsDown(keycode: 56, flags: []))
        #expect(!modifierKeyIsDown(keycode: 55, flags: .maskShift))
    }

    @Test("non-modifier keycodes are never down")
    func nonModifier() {
        #expect(!modifierKeyIsDown(keycode: 0, flags: .maskShift))
    }
}

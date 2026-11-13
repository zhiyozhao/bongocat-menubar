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

@Suite("Modifier flagsChanged: left/right copies of the same modifier")
struct ModifierSideTests {
    private func flags(_ generic: CGEventFlags, device: UInt64) -> CGEventFlags {
        CGEventFlags(rawValue: generic.rawValue | device)
    }

    @Test("releasing Left Shift while Right Shift is held reports Left Shift up")
    func leftShiftReleasedRightHeld() {
        let f = flags(.maskShift, device: 0x4)   // only RShift device bit
        #expect(!modifierKeyIsDown(keycode: 56, flags: f))
        #expect(modifierKeyIsDown(keycode: 60, flags: f))
    }

    @Test("releasing Right Cmd while Left Cmd is held reports Right Cmd up")
    func rightCmdReleasedLeftHeld() {
        let f = flags(.maskCommand, device: 0x8) // only LCmd device bit
        #expect(!modifierKeyIsDown(keycode: 54, flags: f))
        #expect(modifierKeyIsDown(keycode: 55, flags: f))
    }

    @Test("Right Ctrl uses its own device bit")
    func rightCtrl() {
        #expect(modifierKeyIsDown(keycode: 62, flags: flags(.maskControl, device: 0x2000)))
        #expect(!modifierKeyIsDown(keycode: 59, flags: flags(.maskControl, device: 0x2000)))
    }

    @Test("Option: each side reads its own bit")
    func option() {
        #expect(modifierKeyIsDown(keycode: 58, flags: flags(.maskAlternate, device: 0x20)))
        #expect(!modifierKeyIsDown(keycode: 61, flags: flags(.maskAlternate, device: 0x20)))
        #expect(modifierKeyIsDown(keycode: 61, flags: flags(.maskAlternate, device: 0x40)))
    }
}

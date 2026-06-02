import Foundation

class KeystrokeAnimator {
    var followHands = false
    var onFrameChange: ((String) -> Void)?

    // Independent hand state (like BongoCat)
    private var leftDown = false
    private var rightDown = false

    // Normal mode state
    private let minInterval: TimeInterval = 1.0 / 60.0
    private var idleTimer: Timer?
    private var toggleFlag = false
    private var lastUpdate: Date = .distantPast
    private var currentFrame: String = "idle"

    // Left-hand keycodes (QWERTY standard macOS)
    private static let leftKeycodes: Set<UInt16> = [
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

    private static let rightKeycodes: Set<UInt16> = [
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

    func keyDown(keycode: UInt16) {
        guard Self.leftKeycodes.contains(keycode) || Self.rightKeycodes.contains(keycode) else { return }
        if followHands {
            handleFollowDown(keycode: keycode)
        } else {
            handleNormalMode()
        }
    }

    func keyUp(keycode: UInt16) {
        guard Self.leftKeycodes.contains(keycode) || Self.rightKeycodes.contains(keycode) else { return }
        if followHands {
            handleFollowUp(keycode: keycode)
        }
    }

    // MARK: - Follow Hands Mode (BongoCat style)

    private func handleFollowDown(keycode: UInt16) {
        let isLeft = Self.leftKeycodes.contains(keycode)
        if isLeft {
            leftDown = true
        } else {
            rightDown = true
        }
        updateFollowFrame()
    }

    private func handleFollowUp(keycode: UInt16) {
        let isLeft = Self.leftKeycodes.contains(keycode)
        if isLeft {
            leftDown = false
        } else {
            rightDown = false
        }
        updateFollowFrame()
    }

    private func updateFollowFrame() {
        let frame: String
        switch (leftDown, rightDown) {
        case (true, true):   frame = "typing_both"
        case (true, false):  frame = "typing_a"
        case (false, true):  frame = "typing_b"
        case (false, false): frame = "idle"
        }

        if frame != currentFrame {
            currentFrame = frame
            onFrameChange?(frame)
        }
    }

    // MARK: - Normal Mode (alternating toggle)

    private func handleNormalMode() {
        let now = Date()
        guard now.timeIntervalSince(lastUpdate) >= minInterval else {
            resetIdleTimer()
            return
        }
        lastUpdate = now

        toggleFlag.toggle()
        let frame = toggleFlag ? "typing_a" : "typing_b"
        currentFrame = frame
        onFrameChange?(frame)
        resetIdleTimer()
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.currentFrame = "idle"
            self?.onFrameChange?("idle")
            self?.lastUpdate = .distantPast
            self?.toggleFlag = false
        }
    }
}

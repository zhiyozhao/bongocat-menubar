import Foundation

public class KeystrokeAnimator {
    public var followHands = false {
        didSet {
            if followHands != oldValue { resetState() }
        }
    }
    public var onFrameChange: ((String) -> Void)?

    // Keys currently held per hand; a paw goes down only when its set is empty.
    private var leftHeld: Set<UInt16> = []
    private var rightHeld: Set<UInt16> = []

    // Normal mode state
    private let minInterval: TimeInterval = 1.0 / 60.0
    static let idleDelay: TimeInterval = 0.5
    private var idleTimer: Timer?
    private var toggleFlag = false
    private var lastUpdate: CFAbsoluteTime = 0
    private(set) var currentFrame: String = "idle"

    /// Time source; injectable so tests can drive Normal mode deterministically.
    var now: () -> CFAbsoluteTime = CFAbsoluteTimeGetCurrent

    public init() {}

    public func keyDown(keycode: UInt16) {
        guard let hand = KeyMap.hand(for: keycode) else { return }
        if followHands {
            handleFollowDown(hand, keycode: keycode)
        } else {
            handleNormalMode()
        }
    }

    public func keyUp(keycode: UInt16) {
        guard let hand = KeyMap.hand(for: keycode) else { return }
        if followHands {
            handleFollowUp(hand, keycode: keycode)
        }
    }

    /// Drop per-mode state when switching modes, so a key held (or an idle timer
    /// pending) in one mode cannot leave a stale frame in the other.
    private func resetState() {
        leftHeld.removeAll()
        rightHeld.removeAll()
        idleTimer?.invalidate()
        idleTimer = nil
        toggleFlag = false
        lastUpdate = 0
        if currentFrame != "idle" {
            currentFrame = "idle"
            onFrameChange?("idle")
        }
    }

    // MARK: - Follow Hands Mode (BongoCat style)

    private func handleFollowDown(_ hand: Hand, keycode: UInt16) {
        if hand == .left {
            leftHeld.insert(keycode)
        } else {
            rightHeld.insert(keycode)
        }
        updateFollowFrame()
    }

    private func handleFollowUp(_ hand: Hand, keycode: UInt16) {
        if hand == .left {
            leftHeld.remove(keycode)
        } else {
            rightHeld.remove(keycode)
        }
        updateFollowFrame()
    }

    private func updateFollowFrame() {
        let frame: String
        switch (!leftHeld.isEmpty, !rightHeld.isEmpty) {
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
        let now = now()
        guard now - lastUpdate >= minInterval else {
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
        if let timer = idleTimer {
            timer.fireDate = Date(timeIntervalSinceNow: Self.idleDelay)
        } else {
            idleTimer = Timer.scheduledTimer(withTimeInterval: Self.idleDelay, repeats: false) { [weak self] _ in
                self?.idleTimerFired()
            }
        }
    }

    /// Normal mode: no key for `idleDelay` → back to idle. Called by the idle timer
    /// (and directly by tests).
    func idleTimerFired() {
        currentFrame = "idle"
        onFrameChange?("idle")
        lastUpdate = 0
        toggleFlag = false
        idleTimer = nil
    }
}

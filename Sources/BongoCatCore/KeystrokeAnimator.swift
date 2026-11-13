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

    /// Asks the system whether a keycode is physically down right now. Used to drop
    /// held keys whose key-up event never reached us (e.g. released while macOS
    /// Secure Input was on). `nil` disables the check.
    public var isKeyDown: ((UInt16) -> Bool)?
    static let pruneInterval: TimeInterval = 1.0
    private(set) var pruneTimer: Timer?

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
        stopPruneTimer()
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
        dropReleasedKeys(except: keycode)
        if hand == .left {
            leftHeld.insert(keycode)
        } else {
            rightHeld.insert(keycode)
        }
        updateFollowFrame()
    }

    private func handleFollowUp(_ hand: Hand, keycode: UInt16) {
        dropReleasedKeys(except: keycode)
        if hand == .left {
            leftHeld.remove(keycode)
        } else {
            rightHeld.remove(keycode)
        }
        updateFollowFrame()
    }

    /// Remove held keys the system reports as up, then refresh the frame.
    /// Called on every Follow-mode event and by the periodic check.
    func pruneReleasedKeys() {
        dropReleasedKeys(except: nil)
        updateFollowFrame()
    }

    /// The key of the event being handled is excluded: its own down/up event is
    /// authoritative, and the async hop to the main thread means the live key
    /// state may already be newer than the event.
    private func dropReleasedKeys(except keycode: UInt16?) {
        guard let isKeyDown else { return }
        leftHeld = leftHeld.filter { $0 == keycode || isKeyDown($0) }
        rightHeld = rightHeld.filter { $0 == keycode || isKeyDown($0) }
    }

    private func updatePruneTimer() {
        let holding = !leftHeld.isEmpty || !rightHeld.isEmpty
        if holding && isKeyDown != nil {
            guard pruneTimer == nil else { return }
            pruneTimer = Timer.scheduledTimer(withTimeInterval: Self.pruneInterval, repeats: true) { [weak self] _ in
                self?.pruneReleasedKeys()
            }
        } else {
            stopPruneTimer()
        }
    }

    private func stopPruneTimer() {
        pruneTimer?.invalidate()
        pruneTimer = nil
    }

    private func updateFollowFrame() {
        updatePruneTimer()
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

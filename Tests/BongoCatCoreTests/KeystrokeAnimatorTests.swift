import Foundation
import Testing
@testable import BongoCatCore

private let keyA: UInt16 = 0       // left
private let keyS: UInt16 = 1       // left
private let keyJ: UInt16 = 38      // right
private let keypad1: UInt16 = 83   // not mapped

/// Records every frame the animator emits.
private final class Recorder {
    var frames: [String] = []
}

private func makeAnimator(followHands: Bool, clock: @escaping () -> CFAbsoluteTime = { 0 }) -> (KeystrokeAnimator, Recorder) {
    let animator = KeystrokeAnimator()
    let recorder = Recorder()
    animator.followHands = followHands
    animator.now = clock
    animator.onFrameChange = { recorder.frames.append($0) }
    return (animator, recorder)
}

@Suite("Follow Hands mode")
struct FollowHandsTests {
    @Test("left key → typing_a, release → idle")
    func leftHand() {
        let (animator, rec) = makeAnimator(followHands: true)
        animator.keyDown(keycode: keyA)
        animator.keyUp(keycode: keyA)
        #expect(rec.frames == ["typing_a", "idle"])
    }

    @Test("right key → typing_b, release → idle")
    func rightHand() {
        let (animator, rec) = makeAnimator(followHands: true)
        animator.keyDown(keycode: keyJ)
        animator.keyUp(keycode: keyJ)
        #expect(rec.frames == ["typing_b", "idle"])
    }

    @Test("both hands down → typing_both; releasing one goes back to the other hand")
    func bothHands() {
        let (animator, rec) = makeAnimator(followHands: true)
        animator.keyDown(keycode: keyA)
        animator.keyDown(keycode: keyJ)
        animator.keyUp(keycode: keyA)
        animator.keyUp(keycode: keyJ)
        #expect(rec.frames == ["typing_a", "typing_both", "typing_b", "idle"])
    }

    @Test("key auto-repeat does not emit duplicate frames")
    func noDuplicateFrames() {
        let (animator, rec) = makeAnimator(followHands: true)
        animator.keyDown(keycode: keyA)
        animator.keyDown(keycode: keyA)
        animator.keyDown(keycode: keyS)
        #expect(rec.frames == ["typing_a"])
    }

    @Test("unmapped keys are ignored")
    func unmappedIgnored() {
        let (animator, rec) = makeAnimator(followHands: true)
        animator.keyDown(keycode: keypad1)
        animator.keyUp(keycode: keypad1)
        #expect(rec.frames.isEmpty)
    }
}

@Suite("Normal mode")
struct NormalModeTests {
    @Test("each key press alternates typing_a / typing_b")
    func alternates() {
        var t: CFAbsoluteTime = 100
        let (animator, rec) = makeAnimator(followHands: false, clock: { t })
        for _ in 0..<4 {
            animator.keyDown(keycode: keyA)
            t += 0.1
        }
        #expect(rec.frames == ["typing_a", "typing_b", "typing_a", "typing_b"])
    }

    @Test("hand does not matter in Normal mode")
    func handIrrelevant() {
        var t: CFAbsoluteTime = 100
        let (animator, rec) = makeAnimator(followHands: false, clock: { t })
        animator.keyDown(keycode: keyJ)
        t += 0.1
        animator.keyDown(keycode: keyA)
        #expect(rec.frames == ["typing_a", "typing_b"])
    }

    @Test("key releases do not change the frame")
    func keyUpIgnored() {
        let (animator, rec) = makeAnimator(followHands: false, clock: { 100 })
        animator.keyDown(keycode: keyA)
        animator.keyUp(keycode: keyA)
        #expect(rec.frames == ["typing_a"])
    }

    @Test("presses faster than 60 fps are throttled")
    func throttled() {
        var t: CFAbsoluteTime = 100
        let (animator, rec) = makeAnimator(followHands: false, clock: { t })
        animator.keyDown(keycode: keyA)
        t += 0.005
        animator.keyDown(keycode: keyA)
        t += 0.05
        animator.keyDown(keycode: keyA)
        #expect(rec.frames == ["typing_a", "typing_b"])
    }

    @Test("idle timeout returns to idle and restarts the cycle at typing_a")
    func idleResets() {
        var t: CFAbsoluteTime = 100
        let (animator, rec) = makeAnimator(followHands: false, clock: { t })
        animator.keyDown(keycode: keyA)
        animator.idleTimerFired()
        t += 1
        animator.keyDown(keycode: keyA)
        #expect(rec.frames == ["typing_a", "idle", "typing_a"])
    }

    @Test("idle timer actually fires after the idle delay")
    func idleTimerFires() async throws {
        let (animator, rec) = makeAnimator(followHands: false, clock: { 100 })
        animator.keyDown(keycode: keyA)
        // The timer is scheduled on the current run loop; spin it until it fires.
        let deadline = Date().addingTimeInterval(KeystrokeAnimator.idleDelay + 2)
        while rec.frames.last != "idle" && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        #expect(rec.frames == ["typing_a", "idle"])
    }
}

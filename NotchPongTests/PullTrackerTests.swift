//
//  PullTrackerTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchPong

struct PullTrackerTests {
    private let zone = CGRect(x: 730, y: 900, width: 50, height: 50)

    /// Feeds one pointer reading at x = 756 with the notch bottom at y = 950.
    private func feed(
        _ tracker: inout PullTracker,
        height: CGFloat,
        pressed: Bool,
        at time: TimeInterval,
        startPull: CGFloat = 0,
        grabZone: CGRect?? = .none
    ) -> PointerAction {
        let sample = PointerSample(location: CGPoint(x: 756, y: height), time: time, isPressed: pressed)
        return tracker.handle(sample, grabZone: grabZone ?? zone, startPull: startPull, anchorY: 950)
    }

    @Test func pressInsideZoneStartsPullAtStartValue() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 920, pressed: false, at: 0)
        #expect(feed(&tracker, height: 920, pressed: true, at: 0.016) == .pull(0))
    }

    @Test func draggingDownGrowsPull() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 920, pressed: false, at: 0)
        _ = feed(&tracker, height: 920, pressed: true, at: 0.016)
        #expect(feed(&tracker, height: 620, pressed: true, at: 0.5) == .pull(300))
    }

    @Test func releaseReportsUpwardVelocity() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 920, pressed: false, at: 0, startPull: 300)
        _ = feed(&tracker, height: 920, pressed: true, at: 0.1, startPull: 300)
        _ = feed(&tracker, height: 940, pressed: true, at: 0.2, startPull: 300)
        // Moved up 20 pt in the last 0.1 s before release.
        let action = feed(&tracker, height: 940, pressed: false, at: 0.3, startPull: 300)
        #expect(action == .release(pull: 280, upwardVelocity: 200))
    }

    @Test func pressOutsideZoneIsIgnored() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 500, pressed: false, at: 0)
        #expect(feed(&tracker, height: 500, pressed: true, at: 0.016) == .none)
    }

    @Test func buttonAlreadyHeldWhenEnteringZoneIsIgnored() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 500, pressed: true, at: 0)
        #expect(feed(&tracker, height: 920, pressed: true, at: 0.016) == .none)
    }

    @Test func noZoneMeansNoGrab() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 920, pressed: false, at: 0, grabZone: .some(nil))
        #expect(feed(&tracker, height: 920, pressed: true, at: 0.016, grabZone: .some(nil)) == .none)
    }

    @Test func cancelledPullIgnoresTheRestOfThePress() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 920, pressed: false, at: 0)
        _ = feed(&tracker, height: 920, pressed: true, at: 0.016)
        tracker.cancel()
        #expect(feed(&tracker, height: 800, pressed: true, at: 0.1) == .none)
        #expect(feed(&tracker, height: 800, pressed: false, at: 0.2) == .none)
    }

    @Test func newPressAfterCancelGrabsAgain() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 920, pressed: false, at: 0)
        _ = feed(&tracker, height: 920, pressed: true, at: 0.016)
        tracker.cancel()
        _ = feed(&tracker, height: 920, pressed: false, at: 0.1)
        #expect(feed(&tracker, height: 920, pressed: true, at: 0.2) == .pull(0))
    }
}

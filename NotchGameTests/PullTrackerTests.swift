//
//  PullTrackerTests.swift
//  NotchGameTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGame

struct PullTrackerTests {
    private let zone = CGRect(x: 730, y: 900, width: 50, height: 50)

    /// Feeds one pointer reading at x = 756 with the notch bottom at y = 950.
    private func feed(
        _ tracker: inout PullTracker,
        height: CGFloat,
        pressed: Bool,
        at time: TimeInterval,
        startPull: CGFloat = 0,
        gain: CGFloat = 1,
        grabZone: CGRect?? = .none
    ) -> PointerAction {
        let sample = PointerSample(location: CGPoint(x: 756, y: height), time: time, isPressed: pressed)
        return tracker.handle(sample, grabZone: grabZone ?? zone, startPull: startPull, gain: gain, anchorY: 950)
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

    @Test func gainMakesThePullGrowFasterThanThePointer() {
        var tracker = PullTracker()
        _ = feed(&tracker, height: 920, pressed: false, at: 0)
        _ = feed(&tracker, height: 920, pressed: true, at: 0.016, startPull: 40, gain: 1.5)
        #expect(feed(&tracker, height: 820, pressed: true, at: 0.5, startPull: 40, gain: 1.5) == .pull(190))
    }
}

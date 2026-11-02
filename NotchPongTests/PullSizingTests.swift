//
//  PullSizingTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct PullSizingTests {
    @Test func pullMapsToCourtAspect() {
        #expect(PullSizing.bodySize(forPull: 300) == CGSize(width: 480, height: 300))
    }

    @Test func pullClampsAtMax() {
        #expect(PullSizing.bodySize(forPull: 900) == CGSize(width: 640, height: 400))
    }

    @Test func negativePullIsZero() {
        #expect(PullSizing.bodySize(forPull: -50) == .zero)
    }

    @Test func releaseBelowMinCloses() {
        #expect(PullSizing.releaseOutcome(pull: 249, upwardVelocity: 0) == .close)
    }

    @Test func releaseAtMinOpensAtMin() {
        #expect(PullSizing.releaseOutcome(pull: 250, upwardVelocity: 0) == .open(CGSize(width: 400, height: 250)))
    }

    @Test func releasePastMaxOpensAtMax() {
        #expect(PullSizing.releaseOutcome(pull: 700, upwardVelocity: 0) == .open(CGSize(width: 640, height: 400)))
    }

    @Test func upwardFlickClosesEvenWhenLarge() {
        #expect(PullSizing.releaseOutcome(pull: 380, upwardVelocity: 1200) == .close)
    }
}

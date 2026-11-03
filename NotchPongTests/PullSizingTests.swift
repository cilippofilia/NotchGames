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
        #expect(PullSizing.bodySize(forPull: 300, aspect: 1.6) == CGSize(width: 480, height: 300))
    }

    @Test func pullClampsAtMax() {
        #expect(PullSizing.bodySize(forPull: 900, aspect: 1.6) == CGSize(width: 736, height: 460))
    }

    @Test func negativePullIsZero() {
        #expect(PullSizing.bodySize(forPull: -50, aspect: 1.6) == .zero)
    }

    @Test func releaseBelowMinCloses() {
        #expect(PullSizing.releaseOutcome(pull: 249, upwardVelocity: 0, aspect: 1.6) == .close)
    }

    @Test func releaseAtMinOpensAtMin() {
        let outcome = PullSizing.releaseOutcome(pull: 250, upwardVelocity: 0, aspect: 1.6)
        #expect(outcome == .open(CGSize(width: 400, height: 250)))
    }

    @Test func releasePastMaxOpensAtMax() {
        let outcome = PullSizing.releaseOutcome(pull: 700, upwardVelocity: 0, aspect: 1.6)
        #expect(outcome == .open(CGSize(width: 736, height: 460)))
    }

    @Test func upwardFlickClosesEvenWhenLarge() {
        #expect(PullSizing.releaseOutcome(pull: 380, upwardVelocity: 1200, aspect: 1.6) == .close)
    }

    @Test func rubberBandFollowsPullUpToMax() {
        #expect(PullSizing.rubberBandedHeight(forPull: 300) == 300)
    }

    @Test func rubberBandStretchesPastMaxWithResistance() {
        let height = PullSizing.rubberBandedHeight(forPull: 560)
        #expect(height > 460 && height < 500)
    }

    @Test func rubberBandStretchIsCapped() {
        #expect(PullSizing.rubberBandedHeight(forPull: 5000) == 460 + PullSizing.maxStretch)
    }

    @Test func rubberBandNeverNegative() {
        #expect(PullSizing.rubberBandedHeight(forPull: -40) == 0)
    }

    @Test func portraitPanelKeepsItsHeight() {
        #expect(PullSizing.bodySize(forPull: 900, aspect: 0.8) == CGSize(width: 368, height: 460))
    }
}

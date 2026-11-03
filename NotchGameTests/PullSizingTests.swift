//
//  PullSizingTests.swift
//  NotchGameTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchGame

struct PullSizingTests {
    @Test func pullMapsToCourtAspect() {
        #expect(PullSizing.bodySize(forPull: 300, shape: .wide) == CGSize(width: 480, height: 300))
    }

    @Test func pullClampsAtMax() {
        #expect(PullSizing.bodySize(forPull: 900, shape: .wide) == CGSize(width: 736, height: 460))
    }

    @Test func negativePullIsZero() {
        #expect(PullSizing.bodySize(forPull: -50, shape: .wide) == .zero)
    }

    @Test func releaseBelowMinCloses() {
        #expect(PullSizing.releaseOutcome(pull: 249, upwardVelocity: 0, shape: .wide) == .close)
    }

    @Test func releaseAtMinOpensAtMin() {
        let outcome = PullSizing.releaseOutcome(pull: 250, upwardVelocity: 0, shape: .wide)
        #expect(outcome == .open(CGSize(width: 400, height: 250)))
    }

    @Test func releasePastMaxOpensAtMax() {
        let outcome = PullSizing.releaseOutcome(pull: 700, upwardVelocity: 0, shape: .wide)
        #expect(outcome == .open(CGSize(width: 736, height: 460)))
    }

    @Test func upwardFlickClosesEvenWhenLarge() {
        #expect(PullSizing.releaseOutcome(pull: 380, upwardVelocity: 1200, shape: .wide) == .close)
    }

    @Test func rubberBandFollowsPullUpToMax() {
        #expect(PullSizing.rubberBandedHeight(forPull: 300, maxHeight: PullSizing.maxBodyHeight) == 300)
    }

    @Test func rubberBandStretchesPastMaxWithResistance() {
        let height = PullSizing.rubberBandedHeight(forPull: 560, maxHeight: PullSizing.maxBodyHeight)
        #expect(height > 460 && height < 500)
    }

    @Test func rubberBandStretchIsCapped() {
        let height = PullSizing.rubberBandedHeight(forPull: 5000, maxHeight: PullSizing.maxBodyHeight)
        #expect(height == 460 + PullSizing.maxStretch)
    }

    @Test func rubberBandNeverNegative() {
        #expect(PullSizing.rubberBandedHeight(forPull: -40, maxHeight: PullSizing.maxBodyHeight) == 0)
    }

    @Test func tallPanelReachesItsOwnHeight() {
        #expect(PullSizing.bodySize(forPull: 900, shape: .tall) == CGSize(width: 416, height: 520))
    }

    @Test func tallPanelHasNoSmallSizes() {
        let short = PullSizing.releaseOutcome(pull: 260, upwardVelocity: 0, shape: .tall)
        let long = PullSizing.releaseOutcome(pull: 900, upwardVelocity: 0, shape: .tall)
        #expect(short == .open(CGSize(width: 416, height: 520)))
        #expect(long == .open(CGSize(width: 416, height: 520)))
        #expect(PullSizing.releaseOutcome(pull: 249, upwardVelocity: 0, shape: .tall) == .close)
    }
}

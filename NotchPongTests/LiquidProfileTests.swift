//
//  LiquidProfileTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct LiquidProfileTests {
    @Test func shortLengthIsADrip() {
        let profile = LiquidProfile.make(length: Magnet.maxLength, notchWidth: 190, dropOffset: 10)
        #expect(profile.solidity == 0)
        #expect(profile.attachHalfWidth == LiquidProfile.dripHalfWidth)
        #expect(profile.bodyHalfWidth == LiquidProfile.dripHalfWidth)
        #expect(profile.flare == LiquidProfile.maxFlare)
        #expect(profile.offsetX == 10)
    }

    @Test func fullLengthIsThePanel() {
        let profile = LiquidProfile.make(length: 400 + LiquidProfile.slack, notchWidth: 190, dropOffset: 10)
        #expect(profile.solidity == 1)
        #expect(profile.attachHalfWidth == 95)
        #expect(profile.bodyHalfWidth == 320)
        #expect(profile.flare == 0)
        #expect(profile.transition == LiquidProfile.slack)
        #expect(profile.offsetX == 0)
        #expect(profile.requiredWidth == 640)
    }

    @Test func morphHasNoJumps() {
        let before = LiquidProfile.make(length: 140, notchWidth: 190, dropOffset: 30)
        let after = LiquidProfile.make(length: 140.5, notchWidth: 190, dropOffset: 30)
        #expect(abs(before.bodyHalfWidth - after.bodyHalfWidth) < 2)
        #expect(abs(before.attachHalfWidth - after.attachHalfWidth) < 1)
        #expect(abs(before.offsetX - after.offsetX) < 1)
    }

    @Test func bodyNeverNarrowerThanDrip() {
        let profile = LiquidProfile.make(length: 60, notchWidth: 190, dropOffset: 0)
        #expect(profile.bodyHalfWidth >= LiquidProfile.dripHalfWidth)
    }

    @Test(arguments: Array(stride(from: 0, through: 420, by: 10)))
    func neckIsNeverWiderThanBody(length: Int) {
        let profile = LiquidProfile.make(length: CGFloat(length), notchWidth: 190, dropOffset: 0)
        #expect(profile.attachHalfWidth <= profile.bodyHalfWidth)
    }
}

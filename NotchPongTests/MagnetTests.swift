//
//  MagnetTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct MagnetTests {
    private let notchBottom = CGPoint(x: 756, y: 950)

    @Test func farPointerShowsNoTear() {
        let pose = Magnet.tear(pointer: CGPoint(x: 756, y: 500), notchBottomCenter: notchBottom)
        #expect(pose == TearPose(length: 0, offsetX: 0))
    }

    @Test func pointerAtNotchShowsFullTear() {
        let pose = Magnet.tear(pointer: notchBottom, notchBottomCenter: notchBottom)
        #expect(pose.length == Magnet.maxLength)
    }

    @Test func tearGrowsAsPointerGetsCloser() {
        let far = Magnet.tear(pointer: CGPoint(x: 756, y: 850), notchBottomCenter: notchBottom)
        let near = Magnet.tear(pointer: CGPoint(x: 756, y: 900), notchBottomCenter: notchBottom)
        #expect(far.length > 0)
        #expect(near.length > far.length)
    }

    @Test func tearLeansTowardPointerWithinLimit() {
        let right = Magnet.tear(pointer: CGPoint(x: 806, y: 930), notchBottomCenter: notchBottom)
        let farRight = Magnet.tear(pointer: CGPoint(x: 900, y: 940), notchBottomCenter: notchBottom)
        #expect(right.offsetX > 0)
        #expect(farRight.offsetX <= Magnet.maxLean)
    }
}

//
//  DropGeometryTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct DropGeometryTests {
    @Test func dripIsNarrowAndKeepsItsOffset() {
        #expect(DropGeometry.width(forLength: Magnet.maxLength) == DropGeometry.dripWidth)
        #expect(DropGeometry.offset(forLength: Magnet.maxLength, dropOffset: 30) == 30)
        #expect(DropGeometry.solidity(forLength: Magnet.maxLength) == 0)
    }

    @Test func fullLengthIsTheCenteredPanel() {
        let length = PullSizing.maxBodyHeight
        #expect(DropGeometry.width(forLength: length) == length * PullSizing.aspect)
        #expect(DropGeometry.offset(forLength: length, dropOffset: 30) == 0)
        #expect(DropGeometry.solidity(forLength: length) == 1)
    }

    @Test func growsWithoutJumps() {
        #expect(abs(DropGeometry.width(forLength: 140) - DropGeometry.width(forLength: 140.5)) < 2)
        #expect(DropGeometry.width(forLength: 0) == DropGeometry.dripWidth)
    }

    @Test func restingDripHasANarrowTop() {
        let width = DropGeometry.attachWidth(forLength: Magnet.maxLength, notchWidth: 190, dropOffset: 30)
        #expect(width == DropGeometry.dripTopWidth)
    }

    @Test func pulledDropHangsFromTheWholeNotch() {
        let width = DropGeometry.attachWidth(forLength: 300, notchWidth: 190, dropOffset: 0)
        #expect(width == 190 - 2 * DropGeometry.attachInset)
    }

    @Test(arguments: [0, 40, 80, 120, 160, 240, 460])
    func topNeverReachesPastTheNotch(length: Int) {
        let length = CGFloat(length)
        let half = DropGeometry.attachWidth(forLength: length, notchWidth: 190, dropOffset: 49) / 2
        let offset = DropGeometry.offset(forLength: length, dropOffset: 49)
        #expect(half + abs(offset) <= 95 - DropGeometry.attachInset + 0.001)
    }

    @Test func frameHoldsBothTopAndBody() {
        let frame = DropGeometry.frameWidth(forLength: 60, notchWidth: 190, dropOffset: 30)
        #expect(frame >= DropGeometry.width(forLength: 60))
        #expect(frame >= DropGeometry.attachWidth(forLength: 60, notchWidth: 190, dropOffset: 30))
    }
}

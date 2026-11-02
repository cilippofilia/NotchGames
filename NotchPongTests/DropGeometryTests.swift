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

    @Test func dripClingsWithAWiderTop() {
        #expect(DropGeometry.topWidth(forLength: Magnet.maxLength) == DropGeometry.dripTopWidth)
        #expect(DropGeometry.frameWidth(forLength: Magnet.maxLength) == DropGeometry.dripTopWidth)
    }

    @Test func panelTopLeavesRoomForRoundedCorners() {
        let length = PullSizing.maxBodyHeight
        let width = DropGeometry.width(forLength: length)
        #expect(DropGeometry.topWidth(forLength: length) == width - 2 * DropGeometry.cornerRadius)
        #expect(DropGeometry.frameWidth(forLength: length) == width)
    }

    @Test func topChangesWithoutJumps() {
        #expect(abs(DropGeometry.topWidth(forLength: 140) - DropGeometry.topWidth(forLength: 140.5)) < 2)
    }
}

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
    private let maxShift: CGFloat = 73

    private func tear(at pointer: CGPoint) -> TearPose {
        Magnet.tear(pointer: pointer, notchBottomCenter: notchBottom, maxShift: maxShift)
    }

    @Test func farPointerShowsNoTear() {
        #expect(tear(at: CGPoint(x: 756, y: 500)) == TearPose(length: 0, offsetX: 0))
    }

    @Test func pointerAtNotchShowsFullTear() {
        #expect(tear(at: notchBottom).length == Magnet.maxLength)
    }

    @Test func tearGrowsAsPointerGetsCloser() {
        let far = tear(at: CGPoint(x: 756, y: 850))
        let near = tear(at: CGPoint(x: 756, y: 900))
        #expect(far.length > 0)
        #expect(near.length > far.length)
    }

    @Test func tearSlidesRightAbovePointer() {
        let pose = tear(at: CGPoint(x: 806, y: 900))
        #expect(pose.offsetX == 50)
    }

    @Test func pointerJustUnderNotchSideGetsFullTear() {
        #expect(tear(at: CGPoint(x: 806, y: 950)).length == Magnet.maxLength)
    }

    @Test func tearStopsAtNotchEdge() {
        #expect(tear(at: CGPoint(x: 900, y: 940)).offsetX == maxShift)
        #expect(tear(at: CGPoint(x: 600, y: 940)).offsetX == -maxShift)
    }

    @Test func dropStaysClearOfNotchCorners() {
        let notchWidth: CGFloat = 190
        let shift = Magnet.maxShift(notchWidth: notchWidth)
        let footprint = DropGeometry.dripWidth / 2
        #expect(shift + footprint <= notchWidth / 2 - Magnet.cornerInset)
    }

    @Test func narrowNotchKeepsDropCentered() {
        #expect(Magnet.maxShift(notchWidth: 60) == 0)
    }
}

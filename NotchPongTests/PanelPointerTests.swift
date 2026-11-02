//
//  PanelPointerTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct PanelPointerTests {
    // Screen coordinates (y up): a 400 × 250 panel whose top edge is at y = 900.
    private let panel = CGRect(x: 100, y: 650, width: 400, height: 250)

    @Test func insideThePanelIsMeasuredFromItsTopLeft() {
        #expect(PanelPointer.position(of: CGPoint(x: 150, y: 880), in: panel) == CGPoint(x: 50, y: 20))
    }

    @Test func justOutsideTheEdgeStillCounts() {
        let point = CGPoint(x: 100 - PanelPointer.gutter + 1, y: 700)
        #expect(PanelPointer.position(of: point, in: panel) != nil)
    }

    @Test func wellOutsideTheGutterPauses() {
        let point = CGPoint(x: 100 - PanelPointer.gutter - 1, y: 700)
        #expect(PanelPointer.position(of: point, in: panel) == nil)
    }
}

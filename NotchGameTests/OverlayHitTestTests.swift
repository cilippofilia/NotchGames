//
//  OverlayHitTestTests.swift
//  NotchGameTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchGame

struct OverlayHitTestTests {
    private let drop = CGRect(x: 100, y: 100, width: 28, height: 40)
    private let grabZone = CGRect(x: 90, y: 94, width: 48, height: 46)

    @Test func clickBesideTheDropButInsideTheGrabZoneIsCaught() {
        let point = CGPoint(x: 93, y: 120)
        #expect(OverlayHitTest.catchesClicks(at: point, phase: .closed, dropRect: drop, grabZone: grabZone))
    }

    @Test func clickOutsideBothPassesThrough() {
        let point = CGPoint(x: 300, y: 300)
        #expect(!OverlayHitTest.catchesClicks(at: point, phase: .closed, dropRect: drop, grabZone: grabZone))
    }

    @Test func dragAlwaysKeepsTheMouse() {
        let point = CGPoint(x: 300, y: 300)
        #expect(OverlayHitTest.catchesClicks(at: point, phase: .dragging, dropRect: drop, grabZone: nil))
    }
}

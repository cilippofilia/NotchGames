//
//  PanelPointerTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchGames

struct PanelPointerTests {
    // Screen coordinates (y up): a 400 × 250 panel whose top edge is at y = 900.
    private let panel = CGRect(x: 100, y: 650, width: 400, height: 250)

    @Test func insideThePanelIsMeasuredFromItsTopLeft() {
        let position = PanelPointer.position(of: CGPoint(x: 150, y: 880), in: panel, gutter: 80)
        #expect(position == CGPoint(x: 50, y: 20))
    }

    @Test(arguments: GutterSize.allCases)
    func justInsideTheGutterStillCounts(size: GutterSize) {
        let point = CGPoint(x: 100 - size.points + 1, y: 700)
        #expect(PanelPointer.position(of: point, in: panel, gutter: size.points) != nil)
    }

    @Test(arguments: GutterSize.allCases)
    func beyondTheGutterPauses(size: GutterSize) {
        let point = CGPoint(x: 100 - size.points - 1, y: 700)
        #expect(PanelPointer.position(of: point, in: panel, gutter: size.points) == nil)
    }

    @Test func mediumIsTheDefaultAt80Points() {
        #expect(GutterSize.standard == .medium)
        #expect(GutterSize.medium.points == 80)
        #expect(GutterSize.largest.points == GutterSize.allCases.map(\.points).max())
    }
}

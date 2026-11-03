//
//  BrickWallTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct BrickWallTests {
    @Test func newWallIsFull() {
        let wall = BrickWall(rows: 3)
        #expect(wall.rows.count == 3)
        #expect(wall.rows.allSatisfy { $0.count == BrickWall.columns && $0.allSatisfy { $0 } })
    }

    @Test func droppingARowPushesTheWallDown() throws {
        var wall = BrickWall(rows: 2)
        let before = try #require(wall.lowestBrickBottom)
        wall.dropRow()
        let after = try #require(wall.lowestBrickBottom)
        #expect(abs(after - before - (BrickWall.rowHeight + BrickWall.gap)) < 0.0001)
    }

    @Test func emptiedBottomRowsAreDropped() {
        var wall = BrickWall(rows: 2)
        for column in 0..<BrickWall.columns { wall.breakBrick(row: 1, column: column) }
        #expect(wall.rows.count == 1)
        for column in 0..<BrickWall.columns { wall.breakBrick(row: 0, column: column) }
        #expect(wall.lowestBrickBottom == nil)
    }

    @Test func bricksTileTheCourtWidth() {
        let wall = BrickWall(rows: 1)
        let first = wall.rect(row: 0, column: 0, courtWidth: 0.8)
        let last = wall.rect(row: 0, column: BrickWall.columns - 1, courtWidth: 0.8)
        #expect(first.minX > 0 && last.maxX < 0.8)
        #expect(first.minY == BrickWall.top)
    }
}

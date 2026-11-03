//
//  SnakeModelTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import Testing
@testable import NotchGames

struct SnakeModelTests {
    /// Deterministic food placement (SplitMix64). A generator stuck on one value can make `randomElement` spin forever.
    private struct FixedGenerator: RandomNumberGenerator {
        var state: UInt64 = 42
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var mixed = state
            mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
            mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
            return mixed ^ (mixed >> 31)
        }
    }

    private var generator = FixedGenerator()
    private let farFood = GridCell(column: 0, row: 0)

    private func snake(_ cells: [(Int, Int)], heading: HeldKeys.Direction, walls: Bool = true) -> SnakeModel {
        SnakeModel(
            body: cells.map { GridCell(column: $0.0, row: $0.1) },
            heading: heading,
            food: farFood,
            hasWalls: walls
        )
    }

    @Test mutating func movesOneCellAndKeepsItsLength() {
        var model = snake([(5, 5), (4, 5), (3, 5)], heading: .right)
        model.step(generator: &generator)
        #expect(model.body == [GridCell(column: 6, row: 5), GridCell(column: 5, row: 5), GridCell(column: 4, row: 5)])
    }

    @Test mutating func eatingGrowsScoresAndMovesTheFood() {
        var model = snake([(5, 5), (4, 5), (3, 5)], heading: .right)
        model.food = GridCell(column: 6, row: 5)
        model.step(generator: &generator)
        #expect(model.body.count == 4)
        #expect(model.score == SnakeModel.foodPoints)
        #expect(!model.body.contains(model.food))
        #expect(model.stepInterval < SnakeModel.slowestStep)
    }

    @Test mutating func wallsEndTheRunAndNoWallsWrap() {
        var walled = snake([(31, 5), (30, 5), (29, 5)], heading: .right)
        walled.step(generator: &generator)
        #expect(walled.isOver)

        var open = snake([(31, 5), (30, 5), (29, 5)], heading: .right, walls: false)
        open.step(generator: &generator)
        #expect(!open.isOver)
        #expect(open.head == GridCell(column: 0, row: 5))

        var top = snake([(5, 0), (5, 1), (5, 2)], heading: .up, walls: false)
        top.step(generator: &generator)
        #expect(top.head == GridCell(column: 5, row: SnakeModel.rows - 1))
    }

    @Test mutating func runningIntoItselfEndsTheRun() {
        // A hook: heading up from (5,5) runs into (5,4).
        var model = snake([(5, 5), (6, 5), (6, 4), (5, 4), (4, 4)], heading: .left)
        model.turn(.up)
        model.step(generator: &generator)
        #expect(model.isOver)
    }

    @Test mutating func chasingItsOwnTailIsSafe() {
        // A 2×2 loop: the head moves into the cell the tail is leaving.
        var model = snake([(5, 5), (5, 6), (6, 6), (6, 5)], heading: .up)
        model.turn(.right)
        model.step(generator: &generator)
        #expect(!model.isOver)
        #expect(model.head == GridCell(column: 6, row: 5))
    }

    @Test mutating func quickDoubleTurnCantReverseIntoItself() {
        var model = snake([(5, 5), (4, 5), (3, 5)], heading: .right)
        model.turn(.up)
        model.turn(.left)
        model.step(generator: &generator)
        model.step(generator: &generator)
        #expect(!model.isOver)
        #expect(model.head == GridCell(column: 4, row: 4))
        // Reversing straight back is ignored.
        model.turn(.right)
        model.step(generator: &generator)
        #expect(model.head == GridCell(column: 3, row: 4))
    }

    @Test mutating func firstPressBackwardsTurnsTheSnakeAround() {
        var model = SnakeModel(generator: &generator)
        let tail = model.body.last
        model.turn(.left)
        model.step(generator: &generator)
        #expect(!model.isOver)
        #expect(model.head == tail.map { GridCell(column: $0.column - 1, row: $0.row) })
    }

    @Test func speedsUpToAFloor() {
        let long = SnakeModel(
            body: (0..<200).map { GridCell(column: $0 % SnakeModel.columns, row: $0 / SnakeModel.columns) },
            heading: .right,
            food: GridCell(column: 0, row: 19),
            hasWalls: true
        )
        #expect(long.stepInterval == SnakeModel.fastestStep)
    }
}

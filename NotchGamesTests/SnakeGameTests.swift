//
//  SnakeGameTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import Foundation
import Testing
@testable import NotchGames

@MainActor
struct SnakeGameTests {
    private static let frame: TimeInterval = 1.0 / 60

    private func freshStats() throws -> StatsStore {
        StatsStore(defaults: try #require(UserDefaults(suiteName: "SnakeGameTests-\(UUID())")))
    }

    @discardableResult
    private func run(_ game: SnakeGame, from start: Date, for seconds: TimeInterval) -> Date {
        var now = start
        for _ in 0..<Int((seconds / Self.frame).rounded()) {
            now = now.addingTimeInterval(Self.frame)
            game.tick(now: now)
        }
        return now
    }

    @Test func anArrowStartsTheRunAndTheSnakeMoves() throws {
        let game = SnakeGame(stats: try freshStats())
        #expect(game.display.isPaused)
        let start = game.model.head
        game.press(.up)
        #expect(!game.display.isPaused)
        var now = run(game, from: .now, for: SnakeGame.countdownLength + 0.05)
        #expect(game.model.head == start)
        now = run(game, from: now, for: 0.5)
        #expect(game.model.head.column == start.column)
        #expect(start.row - game.model.head.row >= 3)
        game.togglePause()
        let paused = game.model.head
        run(game, from: now, for: 0.5)
        #expect(game.model.head == paused)
    }

    @Test func hittingAWallEndsTheRunAndRecordsTheBestOnce() throws {
        let stats = try freshStats()
        let model = SnakeModel(
            body: [GridCell(column: 0, row: 5), GridCell(column: 1, row: 5), GridCell(column: 2, row: 5)],
            heading: .left,
            food: GridCell(column: 20, row: 15),
            hasWalls: true
        )
        let game = SnakeGame(model: model, stats: stats)
        game.press(.left)
        run(game, from: .now, for: SnakeGame.countdownLength + 1)
        #expect(game.display.isOver)
        #expect(stats.stats.bestScore(for: .snake) == 0)
        game.reset()
        #expect(!game.display.isOver)
        #expect(game.display.isPaused)
    }
}

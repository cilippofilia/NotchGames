//
//  RunnerGameTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import Foundation
import Testing
@testable import NotchGames

@MainActor
struct RunnerGameTests {
    private static let frame: TimeInterval = 1.0 / 60

    private func freshStats() throws -> StatsStore {
        StatsStore(defaults: try #require(UserDefaults(suiteName: "RunnerGameTests-\(UUID())")))
    }

    @discardableResult
    private func run(_ game: RunnerGame, from start: Date, for seconds: TimeInterval) -> Date {
        var now = start
        for _ in 0..<Int((seconds / Self.frame).rounded()) {
            now = now.addingTimeInterval(Self.frame)
            game.tick(now: now)
        }
        return now
    }

    @Test func jumpStartsTheRunAndEscapePausesIt() throws {
        let game = RunnerGame(stats: try freshStats())
        #expect(game.display.isPaused)
        game.jumpPressed()
        #expect(!game.display.isPaused)
        var now = run(game, from: .now, for: RunnerGame.countdownLength + 0.05)
        now = run(game, from: now, for: 0.5)
        #expect(game.model.distance > 0.2)
        game.togglePause()
        let paused = game.model.distance
        run(game, from: now, for: 0.5)
        #expect(game.model.distance == paused)
    }

    @Test func aCrashRecordsTheBestScore() throws {
        let stats = try freshStats()
        let game = RunnerGame(stats: stats)
        game.jumpPressed()
        // Never jumping, the first cones end the run.
        run(game, from: .now, for: RunnerGame.countdownLength + 5)
        #expect(game.display.isOver)
        #expect(stats.stats.bestScore(for: .runner) == game.model.score)
        #expect(game.display.isNewBest)
        game.reset()
        #expect(!game.display.isOver)
    }
}

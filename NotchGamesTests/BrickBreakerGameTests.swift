//
//  BrickBreakerGameTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation
import Observation
import Synchronization
import Testing
@testable import NotchGames

@MainActor
struct BrickBreakerGameTests {
    private static let frame: TimeInterval = 1.0 / 60

    private func freshStats() throws -> StatsStore {
        StatsStore(defaults: try #require(UserDefaults(suiteName: "BrickBreakerGameTests-\(UUID())")))
    }

    /// A model whose ball hangs still in open court, so nothing but the clock changes.
    private func stillModel() -> BrickBreakerModel {
        var model = BrickBreakerModel()
        model.ball = Ball(position: CGPoint(x: 0.4, y: 0.6), velocity: .zero)
        return model
    }

    /// A model whose ball is about to get past a paddle parked at the far left.
    private func missingModel() -> BrickBreakerModel {
        var model = BrickBreakerModel()
        model.paddleX = 0.1
        model.ball = Ball(position: CGPoint(x: 0.6, y: 0.995), velocity: CGVector(dx: 0, dy: 0.7))
        return model
    }

    /// Ticks frame by frame for `seconds`, returning the time reached.
    @discardableResult
    private func run(_ game: BrickBreakerGame, from start: Date, for seconds: TimeInterval) -> Date {
        var now = start
        for _ in 0..<Int((seconds / Self.frame).rounded()) {
            now = now.addingTimeInterval(Self.frame)
            game.tick(now: now)
        }
        return now
    }

    /// Unpauses and runs through the countdown, returning the time play starts.
    private func startPlay(_ game: BrickBreakerGame) -> Date {
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        return run(game, from: now, for: BrickBreakerGame.countdownLength + 0.05)
    }

    @Test func rowsDropOnlyWhilePlaying() throws {
        let game = BrickBreakerGame(model: stillModel(), stats: try freshStats())
        var now = startPlay(game)
        now = run(game, from: now, for: BrickBreakerModel.baseRowInterval + 0.1)
        #expect(game.model.rowsDropped == 1)
        game.isPaused = true
        run(game, from: now, for: 30)
        #expect(game.model.rowsDropped == 1)
    }

    @Test func survivalPointsCountOnlyPlayTime() throws {
        let game = BrickBreakerGame(model: stillModel(), stats: try freshStats())
        var now = startPlay(game)
        now = run(game, from: now, for: 5.05)
        #expect(game.display.score == 5)
        game.isPaused = true
        run(game, from: now, for: 10)
        #expect(game.display.score == 5)
    }

    @Test func losingABallStartsACountdown() throws {
        let game = BrickBreakerGame(model: missingModel(), stats: try freshStats())
        let now = startPlay(game)
        run(game, from: now, for: Self.frame)
        #expect(game.display.lives == BrickBreakerModel.startingLives - 1)
        #expect(game.display.countdownSeconds == 3)
    }

    @Test func runOverRecordsTheBestScoreOnce() throws {
        let stats = try freshStats()
        var model = missingModel()
        model.dropRow()
        for _ in 0..<2 {
            model.paddleX = 0.1
            model.ball = Ball(position: CGPoint(x: 0.6, y: 0.995), velocity: CGVector(dx: 0, dy: 0.7))
            model.step(by: Self.frame)
        }
        model.ball = Ball(position: CGPoint(x: 0.6, y: 0.995), velocity: CGVector(dx: 0, dy: 0.7))
        let game = BrickBreakerGame(model: model, stats: stats)
        let now = startPlay(game)
        run(game, from: now, for: Self.frame * 2)
        #expect(game.display.isOver)
        #expect(game.display.isNewBest)
        #expect(stats.stats.bestScore(for: .brickBreaker) == BrickBreakerModel.rowPoints)

        var lower = missingModel()
        for _ in 0..<2 {
            lower.paddleX = 0.1
            lower.ball = Ball(position: CGPoint(x: 0.6, y: 0.995), velocity: CGVector(dx: 0, dy: 0.7))
            lower.step(by: Self.frame)
        }
        lower.ball = Ball(position: CGPoint(x: 0.6, y: 0.995), velocity: CGVector(dx: 0, dy: 0.7))
        let second = BrickBreakerGame(model: lower, stats: stats)
        run(second, from: startPlay(second), for: Self.frame * 2)
        #expect(second.display.isOver)
        #expect(!second.display.isNewBest)
        #expect(second.display.best == BrickBreakerModel.rowPoints)
    }

    @Test func displayChangesOnlyOnEvents() throws {
        let game = BrickBreakerGame(model: stillModel(), stats: try freshStats())
        let now = startPlay(game)
        let changed = Mutex(false)
        withObservationTracking { _ = game.display } onChange: { changed.withLock { $0 = true } }
        run(game, from: now, for: 0.5)
        #expect(!changed.withLock { $0 })
    }
}

extension BrickBreakerGameTests {
    @Test func heldKeyGlidesThePaddleAtKeySpeed() throws {
        let game = BrickBreakerGame(model: stillModel(), stats: try freshStats())
        let now = startPlay(game)
        let start = game.model.paddleX
        game.heldKeys.set(.left, isDown: true)
        run(game, from: now, for: 0.1)
        #expect(abs((start - game.model.paddleX) - HeldKeys.speed * 0.1) < 0.01)
        game.heldKeys.set(.left, isDown: false)
        let stopped = game.model.paddleX
        run(game, from: now.addingTimeInterval(0.1), for: 0.1)
        #expect(game.model.paddleX == stopped)
    }
}

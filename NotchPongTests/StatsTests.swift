//
//  StatsTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchPong

struct StatsTests {
    @Test func winsBuildAStreakAndLossesEndIt() {
        var stats = PlayerStats()
        stats.record(winner: .player)
        stats.record(winner: .player)
        stats.record(winner: .computer)
        stats.record(winner: .player)
        #expect(stats == PlayerStats(wins: 3, losses: 1, currentStreak: 1, bestStreak: 2))
    }

    @Test func storeSavesAndLoadsAgain() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
        let store = StatsStore(defaults: defaults)
        store.record(winner: .player)
        store.record(winner: .player)
        let reloaded = StatsStore(defaults: defaults).stats
        #expect(reloaded == PlayerStats(wins: 2, losses: 0, currentStreak: 2, bestStreak: 2))
    }

    @Test func resetClearsEverything() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
        let store = StatsStore(defaults: defaults)
        store.record(winner: .computer)
        store.reset()
        #expect(StatsStore(defaults: defaults).stats == PlayerStats())
    }

    @Test func gameReportsTheWinnerOnce() {
        var model = PongModel()
        var winners: [PongSide] = []
        for _ in 0..<4 {
            model.playerY = 0.1
            model.ball = Ball(position: CGPoint(x: 1.59, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
            model.step(by: 0.03)
        }
        model.playerY = 0.1
        model.ball = Ball(position: CGPoint(x: 1.59, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
        let game = PongGame(model: model)
        game.onMatchEnd = { winner, _ in winners.append(winner) }
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.13))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.16))
        #expect(winners == [.computer])
    }
}

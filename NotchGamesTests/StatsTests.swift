//
//  StatsTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGames

struct StatsTests {
    @Test func winsBuildAStreakAndLossesEndIt() {
        var stats = PlayerStats()
        stats.record(winner: .player, for: .pong)
        stats.record(winner: .player, for: .pong)
        stats.record(winner: .computer, for: .pong)
        stats.record(winner: .player, for: .pong)
        #expect(stats.matchRecord(for: .pong) == MatchRecord(wins: 3, losses: 1, currentStreak: 1, bestStreak: 2))
    }

    @Test func storeSavesAndLoadsAgain() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
        let store = StatsStore(defaults: defaults)
        store.record(winner: .player, for: .pong)
        store.record(winner: .player, for: .pong)
        let reloaded = StatsStore(defaults: defaults).stats
        #expect(reloaded.matchRecord(for: .pong) == MatchRecord(wins: 2, losses: 0, currentStreak: 2, bestStreak: 2))
    }

    @Test func resetClearsOnlyThatGame() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
        let store = StatsStore(defaults: defaults)
        store.record(winner: .computer, for: .pong)
        store.record(winner: .player, for: .airHockey)
        _ = store.recordScore(40, for: .snake)
        store.reset(.pong)
        let reloaded = StatsStore(defaults: defaults).stats
        #expect(reloaded.matchRecord(for: .pong) == MatchRecord())
        #expect(reloaded.matchRecord(for: .airHockey).wins == 1)
        #expect(reloaded.bestScore(for: .snake) == 40)
    }

    @Test func eachGameKeepsItsOwnRecord() {
        var stats = PlayerStats()
        stats.record(winner: .player, for: .airHockey)
        #expect(stats.matchRecord(for: .airHockey).wins == 1)
        #expect(stats.matchRecord(for: .pong) == MatchRecord())
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
        game.onMatchEnd = { winners.append($0) }
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.13))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.16))
        #expect(winners == [.computer])
    }

    @Test func oldSavedStatsStillLoad() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
        defaults.set(Data(#"{"wins":4,"losses":2,"currentStreak":1,"bestStreak":3}"#.utf8), forKey: "stats")
        let stats = StatsStore(defaults: defaults).stats
        #expect(stats.matchRecord(for: .pong) == MatchRecord(wins: 4, losses: 2, currentStreak: 1, bestStreak: 3))
    }

    /// The format shipped before per-game records: one shared record plus best scores. It all goes to Pong.
    @Test func sharedRecordWithBestScoresMovesToPong() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
        let saved = #"{"wins":5,"losses":1,"currentStreak":2,"bestStreak":4,"bestScores":{"snake":90}}"#
        defaults.set(Data(saved.utf8), forKey: "stats")
        let store = StatsStore(defaults: defaults)
        #expect(store.stats.matchRecord(for: .pong) == MatchRecord(wins: 5, losses: 1, currentStreak: 2, bestStreak: 4))
        #expect(store.stats.matchRecord(for: .airHockey) == MatchRecord())
        #expect(store.stats.bestScore(for: .snake) == 90)
        // After a save in the new format, it still loads the same.
        store.record(winner: .player, for: .airHockey)
        let reloaded = StatsStore(defaults: defaults).stats
        #expect(reloaded.matchRecord(for: .pong).wins == 5)
        #expect(reloaded.matchRecord(for: .airHockey).wins == 1)
        #expect(reloaded.bestScore(for: .snake) == 90)
    }

    @Test func onlyAHigherScoreIsANewBest() {
        var stats = PlayerStats()
        let first = stats.recordScore(120, for: .brickBreaker)
        let tie = stats.recordScore(120, for: .brickBreaker)
        let lower = stats.recordScore(80, for: .brickBreaker)
        #expect(first)
        #expect(!tie)
        #expect(!lower)
        #expect(stats.bestScore(for: .brickBreaker) == 120)
        #expect(stats.bestScore(for: .pong) == 0)
    }

    @Test func bestScoresSaveAndReset() throws {
        let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
        let store = StatsStore(defaults: defaults)
        _ = store.recordScore(300, for: .brickBreaker)
        #expect(StatsStore(defaults: defaults).stats.bestScore(for: .brickBreaker) == 300)
        store.reset(.brickBreaker)
        #expect(StatsStore(defaults: defaults).stats.bestScore(for: .brickBreaker) == 0)
    }
}

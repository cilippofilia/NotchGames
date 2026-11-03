//
//  GalleryGameTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGames

@MainActor
struct GalleryGameTests {
    private static let frame: TimeInterval = 1.0 / 60

    private func freshStats() throws -> StatsStore {
        StatsStore(defaults: try #require(UserDefaults(suiteName: "GalleryGameTests-\(UUID())")))
    }

    @discardableResult
    private func run(_ game: GalleryGame, from start: Date, for seconds: TimeInterval) -> Date {
        var now = start
        for _ in 0..<Int((seconds / Self.frame).rounded()) {
            now = now.addingTimeInterval(Self.frame)
            game.tick(now: now)
        }
        return now
    }

    @Test func thePointerStartsAndPausesTheGame() throws {
        let game = GalleryGame(stats: try freshStats())
        #expect(game.display.run.isPaused)
        game.pointerMoved(insidePanel: false)
        #expect(game.display.run.isPaused)
        game.pointerMoved(insidePanel: true)
        #expect(!game.display.run.isPaused)
        game.pointerMoved(insidePanel: nil)
        #expect(game.display.run.isPaused)
    }

    @Test func shotsDontCountDuringTheCountdown() throws {
        let game = GalleryGame(stats: try freshStats())
        game.pointerMoved(insidePanel: true)
        game.shoot(at: CGPoint(x: 0.8, y: 0.5), now: .now)
        #expect(game.lastShotTime == nil)
    }

    @Test func missingTheQuotaRecordsTheBest() throws {
        let stats = try freshStats()
        let game = GalleryGame(stats: stats)
        game.pointerMoved(insidePanel: true)
        var now = run(game, from: .now, for: GalleryGame.countdownLength + 1)
        // Shoot the first bird of the first pair, then let everything else escape.
        if let bird = game.model.birds.first {
            game.shoot(at: bird.position, now: now)
        }
        now = run(game, from: now, for: 40)
        #expect(game.display.run.isOver)
        #expect(stats.stats.bestScore(for: .shootingGallery) == game.model.score)
        #expect(game.model.score > 0)
        game.reset()
        #expect(!game.display.run.isOver)
    }

    @Test func passingARoundWaitsOnTheSummaryUntilTheNextRoundIsAsked() throws {
        let game = GalleryGame(stats: try freshStats())
        game.pointerMoved(insidePanel: true)
        var now = run(game, from: .now, for: GalleryGame.countdownLength + 0.1)
        // Shoot every bird of the round as soon as it's up.
        for _ in 0..<(60 * 60) where game.display.summary == nil {
            for bird in game.model.birds where bird.phase == .flying {
                game.shoot(at: bird.position, now: now)
            }
            now = run(game, from: now, for: 1.0 / 60)
        }
        let summary = try #require(game.display.summary)
        #expect(summary.round == 1)
        #expect(summary.hits == GalleryModel.birdsPerRound)
        #expect(summary.bonus == GalleryModel.perfectBonus)
        #expect(game.display.run.isPaused)
        // Moving the pointer around doesn't skip it.
        game.pointerMoved(insidePanel: true)
        #expect(game.display.run.isPaused)
        game.continueToNextRound()
        #expect(game.display.summary == nil)
        #expect(!game.display.run.isPaused)
        #expect(game.countdown == GalleryGame.countdownLength)
        #expect(game.display.round == 2)
    }
}

//
//  PongEffectsTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchPong

struct PongEffectsTests {
    @Test func pointRecordsWhereAndWhoScored() {
        var model = PongModel()
        model.playerY = 0.1
        model.ball = Ball(position: CGPoint(x: 1.59, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
        let game = PongGame(model: model)
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.13))
        #expect(game.lastPoint?.side == .computer)
        #expect(game.lastPoint?.position.x == PongModel.courtSize.width)
        #expect(abs((game.lastPoint?.position.y ?? 0) - 0.9) < 0.05)
    }

    @Test func explosionStartsTogetherAndSpreadsOut() {
        let start = Explosion.particles(age: 0, side: .computer)
        let later = Explosion.particles(age: 0.3, side: .computer)
        #expect(start.allSatisfy { $0.offset == .zero })
        #expect(later.allSatisfy { hypot($0.offset.dx, $0.offset.dy) > 0 })
    }

    @Test func explosionFliesBackIntoTheCourt() {
        // The computer scored on the right wall, so pieces fly left.
        #expect(Explosion.particles(age: 0.3, side: .computer).allSatisfy { $0.offset.dx <= 0 })
        #expect(Explosion.particles(age: 0.3, side: .player).allSatisfy { $0.offset.dx >= 0 })
    }

    @Test func explosionFadesAway() {
        #expect(Explosion.particles(age: Explosion.duration, side: .player).isEmpty)
    }

    @Test func scorePopsThenSettles() {
        #expect(ScorePulse.scale(age: 0) == ScorePulse.peakScale)
        #expect(ScorePulse.scale(age: ScorePulse.duration / 2) < ScorePulse.peakScale)
        #expect(ScorePulse.scale(age: ScorePulse.duration) == 1)
        #expect(ScorePulse.scale(age: nil) == 1)
    }

    @Test func wallBounceIsRecordedWhereItHit() {
        var model = PongModel()
        model.ball = Ball(position: CGPoint(x: 0.8, y: 0.013), velocity: CGVector(dx: 0.5, dy: -1))
        model.step(by: 0.01)
        #expect(model.wallBounce?.y == 0)
        model.step(by: 0.01)
        #expect(model.wallBounce == nil)
    }

    @Test func gameKeepsTheLastWallHit() {
        var model = PongModel()
        model.ball = Ball(position: CGPoint(x: 0.8, y: 0.987), velocity: CGVector(dx: 0.5, dy: 1))
        let game = PongGame(model: model)
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.11))
        #expect(game.lastWallHit?.position.y == PongModel.courtSize.height)
    }

    @Test func wallSparkFliesBackIntoTheCourt() {
        let fromTop = Explosion.wallSpark(age: 0.1, hitTop: true)
        let fromBottom = Explosion.wallSpark(age: 0.1, hitTop: false)
        #expect(!fromTop.isEmpty)
        #expect(fromTop.allSatisfy { $0.offset.dy >= 0 })
        #expect(fromBottom.allSatisfy { $0.offset.dy <= 0 })
        #expect(Explosion.wallSpark(age: Explosion.sparkDuration, hitTop: true).isEmpty)
    }

    @Test func courtSitsCloseToThePanelEdges() {
        let court = CourtLayout.rect(in: CGSize(width: 640, height: 400))
        #expect(court.minY <= 6)
        #expect(400 - court.maxY <= 6)
    }
}

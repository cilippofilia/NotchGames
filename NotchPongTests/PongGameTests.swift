//
//  PongGameTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchPong

struct PongGameTests {
    @Test func pausedGameDoesNotAdvance() {
        let game = PongGame()
        game.isPaused = true
        let start = game.model.ball
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(0.5))
        #expect(game.model.ball == start)
    }

    @Test func firstTickAfterUnpauseDoesNotJump() {
        let game = PongGame()
        let now = Date.now
        game.tick(now: now)
        game.isPaused = false
        game.tick(now: now.addingTimeInterval(10))
        #expect(abs(game.model.ball.position.x - 0.8) < 0.001)
    }

    @Test func runningGameMovesTheBall() {
        let game = PongGame()
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(1.0 / 60))
        #expect(game.model.ball.position.x > 0.8)
    }

    @Test func resetStartsFreshPausedMatch() {
        let game = PongGame()
        game.isPaused = false
        let now = Date.now
        for frame in 0..<200 { game.tick(now: now.addingTimeInterval(Double(frame) / 60)) }
        game.reset()
        #expect(game.model.playerScore == 0 && game.model.computerScore == 0 && game.model.winner == nil)
        #expect(abs(game.model.ball.position.x - 0.8) < 0.001)
        #expect(game.isPaused)
    }

    @Test func playerPaddleClampsInsideCourt() {
        let game = PongGame()
        game.setPlayerPaddle(y: 2)
        #expect(game.model.playerY <= 1.0 - PongModel.paddleHeight / 2)
    }

    @Test func courtMapsPanelPointsToCourtHeight() {
        let size = CGSize(width: 640, height: 400)
        let court = CourtLayout.rect(in: size)
        #expect(CourtLayout.courtY(forPanelY: court.minY, in: size) == 0)
        #expect(CourtLayout.courtY(forPanelY: court.maxY, in: size) == 1)
        #expect(court.maxY < size.height)
    }
}

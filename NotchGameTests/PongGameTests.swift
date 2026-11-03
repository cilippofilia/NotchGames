//
//  PongGameTests.swift
//  NotchGameTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGame

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

    @Test func unpausingStartsTheCountdown() {
        let game = PongGame()
        game.isPaused = false
        #expect(game.countdown == PongGame.countdownLength)
    }

    @Test func ballWaitsDuringTheCountdown() {
        let game = PongGame()
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(1))
        game.tick(now: now.addingTimeInterval(2))
        #expect(abs(game.model.ball.position.x - 0.8) < 0.001)
        #expect(game.countdown > 0)
    }

    @Test func ballMovesOnceTheCountdownEnds() {
        let game = PongGame()
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.12))
        #expect(game.countdown == 0)
        #expect(game.model.ball.position.x > 0.8)
    }

    @Test func pointStartsANewCountdown() {
        var model = PongModel()
        model.playerY = 0.1
        model.ball = Ball(position: CGPoint(x: 1.59, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
        let game = PongGame(model: model)
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.13))
        #expect(game.model.computerScore == 1)
        #expect(game.countdown == PongGame.countdownLength)
    }

    @Test func resumingAfterAPauseCountsDownAgain() {
        let game = PongGame()
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.isPaused = true
        game.isPaused = false
        #expect(game.countdown == PongGame.countdownLength)
    }

    @Test func countdownDigitsHaveGlyphs() {
        for digit in "123" {
            #expect(PixelFont.glyphs[digit] != nil)
        }
    }

    @Test func paddlesHoldStillDuringTheCountdown() {
        let game = PongGame()
        game.isPaused = false
        let computerStart = game.model.computerY
        let now = Date.now
        game.tick(now: now)
        game.aimPlayerPaddle(y: 0.8)
        game.tick(now: now.addingTimeInterval(1))
        #expect(game.model.computerY == computerStart)
        #expect(game.model.playerY == 0.5)
    }

    @Test func pausedPaddleIgnoresAiming() {
        let game = PongGame()
        game.aimPlayerPaddle(y: 0.8)
        #expect(game.model.playerY == 0.5)
    }

    @Test func paddleJumpsToTheLastAimWhenPlayStarts() {
        let game = PongGame()
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.aimPlayerPaddle(y: 0.8)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        #expect(game.model.playerY == 0.8)
    }

    @Test func paddleFollowsAimDuringPlay() {
        let game = PongGame()
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        game.aimPlayerPaddle(y: 0.3)
        #expect(game.model.playerY == 0.3)
    }

    @Test func pointerInTheGutterDoesNotStartAPausedGame() {
        let game = PongGame()
        game.pointerMoved(toCourtY: 0.5, insidePanel: false)
        #expect(game.isPaused)
    }

    @Test func pointerInsideThePanelStartsTheGame() {
        let game = PongGame()
        game.pointerMoved(toCourtY: 0.5, insidePanel: true)
        #expect(!game.isPaused)
    }

    @Test func pointerInTheGutterKeepsARunningGameGoing() {
        let game = PongGame()
        game.pointerMoved(toCourtY: 0.5, insidePanel: true)
        game.pointerMoved(toCourtY: 0.5, insidePanel: false)
        #expect(!game.isPaused)
    }

    @Test func pointerBeyondTheGutterPauses() {
        let game = PongGame()
        game.pointerMoved(toCourtY: 0.5, insidePanel: true)
        game.pointerMoved(toCourtY: nil, insidePanel: false)
        #expect(game.isPaused)
    }

    @Test func courtMapsPanelPointsToCourtUnits() {
        let size = CGSize(width: 640, height: 400)
        let court = CourtLayout.rect(in: size)
        #expect(CourtLayout.courtPoint(forPanelPoint: CGPoint(x: court.minX, y: court.minY), in: size) == .zero)
        let corner = CourtLayout.courtPoint(forPanelPoint: CGPoint(x: court.maxX, y: court.maxY), in: size)
        #expect(abs(corner.x - PongModel.courtSize.width) < 0.0001)
        #expect(abs(corner.y - PongModel.courtSize.height) < 0.0001)
    }

    @Test func ballTrailKeepsOnlyRecentPositions() {
        let game = PongGame()
        game.isPaused = false
        let start = Date.now.addingTimeInterval(PongGame.countdownLength + 0.1)
        game.tick(now: .now)
        for frame in 0..<30 {
            game.tick(now: start.addingTimeInterval(Double(frame) / 60))
        }
        #expect(!game.ballTrail.isEmpty)
        let newest = start.addingTimeInterval(29.0 / 60)
        #expect(game.ballTrail.allSatisfy { newest.timeIntervalSince($0.time) <= PongGame.trailLength })
    }

    @Test func displayFollowsPauseAndCountdown() {
        let game = PongGame()
        #expect(game.display.isPaused)
        game.isPaused = false
        #expect(game.display == MatchDisplay(isPaused: false, countdownSeconds: 3))
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(1.5))
        #expect(game.display.countdownSeconds == 2)
        game.tick(now: now.addingTimeInterval(PongGame.countdownLength + 0.1))
        #expect(game.display.countdownSeconds == 0)
    }
}

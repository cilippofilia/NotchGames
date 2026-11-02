//
//  AirHockeyGameTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchPong

struct AirHockeyGameTests {
    @Test func computerDefendsItsGoalWhileThePuckIsAway() {
        let puck = Ball(position: CGPoint(x: 1.2, y: 0.3), velocity: .zero)
        let target = AirHockeyOpponent.target(puck: puck, mallet: CGPoint(x: 0.3, y: 0.5))
        #expect(target.x < 0.25)
        #expect(abs(target.y - (0.5 - AirHockeyModel.goalHalfHeight)) < 0.05)
    }

    @Test func computerStrikesTowardThePlayersGoalFromBehind() {
        let puck = Ball(position: CGPoint(x: 0.5, y: 0.5), velocity: .zero)
        #expect(AirHockeyOpponent.target(puck: puck, mallet: CGPoint(x: 0.2, y: 0.5)).x > 0.5)
    }

    @Test func computerGetsBehindAPuckItIsAheadOf() {
        let puck = Ball(position: CGPoint(x: 0.5, y: 0.5), velocity: .zero)
        #expect(AirHockeyOpponent.target(puck: puck, mallet: CGPoint(x: 0.7, y: 0.5)).x < 0.5)
    }

    private func startedGame(_ model: AirHockeyModel = AirHockeyModel()) -> (AirHockeyGame, Date) {
        let game = AirHockeyGame(model: model)
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(MatchClock.countdownLength + 0.1))
        return (game, now.addingTimeInterval(MatchClock.countdownLength + 0.1))
    }

    @Test func malletsHoldStillDuringTheCountdown() {
        let game = AirHockeyGame()
        game.isPaused = false
        let start = game.model.playerMallet
        let now = Date.now
        game.tick(now: now)
        game.aim(at: CGPoint(x: 1.0, y: 0.2))
        game.tick(now: now.addingTimeInterval(1))
        #expect(game.model.playerMallet == start)
    }

    @Test func playerMalletFollowsTheAimDuringPlay() {
        let (game, now) = startedGame()
        game.aim(at: CGPoint(x: 1.0, y: 0.2))
        game.tick(now: now.addingTimeInterval(1.0 / 30))
        #expect(game.model.playerMallet.y < 0.5)
    }

    @Test func secondPlayerDrivesTheLeftMallet() {
        let (game, now) = startedGame()
        game.playerCount = .two
        game.aimLeft(at: CGPoint(x: 0.3, y: 0.9))
        game.tick(now: now.addingTimeInterval(1.0 / 30))
        #expect(game.model.computerMallet.y > 0.5)
    }

    @Test func goalRecordsThePointAndCountsDownAgain() {
        var model = AirHockeyModel()
        model.puck = Ball(position: CGPoint(x: 1.59, y: 0.5), velocity: CGVector(dx: 1, dy: 0))
        let (game, now) = startedGame(model)
        game.tick(now: now.addingTimeInterval(0.03))
        #expect(game.lastPoint?.side == .computer)
        #expect(game.countdown == MatchClock.countdownLength)
    }
}

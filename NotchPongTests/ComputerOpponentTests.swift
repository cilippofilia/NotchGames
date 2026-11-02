//
//  ComputerOpponentTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct ComputerOpponentTests {
    private func incoming(atY height: CGFloat) -> Ball {
        Ball(position: CGPoint(x: 0.5, y: height), velocity: CGVector(dx: -1, dy: 0))
    }

    @Test func movesTowardIncomingBallButNoFasterThanMax() {
        var opponent = ComputerOpponent(reactionDelay: 0)
        let next = opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.9), interval: 0.1)
        #expect(next > 0.5)
        #expect(next - 0.5 <= 0.075 + 0.0001)
    }

    @Test func returnsToCenterWhenBallMovesAway() {
        var opponent = ComputerOpponent(reactionDelay: 0)
        let away = Ball(position: CGPoint(x: 0.5, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
        #expect(opponent.nextPaddleY(current: 0.2, ball: away, interval: 0.1) > 0.2)
    }

    @Test func staysInsideCourt() {
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0)
        let next = opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 1.0), interval: 1)
        #expect(next <= 1.0 - PongModel.paddleHeight / 2)
    }

    @Test func reactsToDelayedBallPosition() {
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0.2, deadZone: 0)
        _ = opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.2), interval: 0.1)
        // Still chasing the older, lower reading.
        #expect(opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.8), interval: 0.05) < 0.5)
    }

    @Test func holdsStillInsideDeadZone() {
        var opponent = ComputerOpponent(reactionDelay: 0)
        #expect(opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.51), interval: 0.1) == 0.5)
    }
}

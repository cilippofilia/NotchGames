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
        #expect(next - 0.5 <= opponent.maxSpeed * 0.1 + 0.0001)
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

    @Test func predictsWhereABouncingBallWillArrive() {
        // Heading up-left steeply: it hits the top wall once, then comes down to the paddle at about 0.58.
        let ball = Ball(position: CGPoint(x: 0.8, y: 0.2), velocity: CGVector(dx: -1, dy: -1))
        let arrival = PongModel.arrivalY(of: ball, atX: PongModel.paddleInset)
        #expect(abs(arrival - 0.584) < 0.01)
    }

    @Test func predictionHandlesSeveralBounces() {
        let ball = Ball(position: CGPoint(x: 1.5, y: 0.5), velocity: CGVector(dx: -0.4, dy: 1.6))
        let arrival = PongModel.arrivalY(of: ball, atX: PongModel.paddleInset)
        #expect(arrival >= PongModel.ballRadius && arrival <= 1 - PongModel.ballRadius)
    }

    @Test func nearbyBallIsReadOffTheWall() {
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0)
        // Close to the paddle and above it, but about to bounce off the top wall and arrive lower.
        let ball = Ball(position: CGPoint(x: 0.25, y: 0.05), velocity: CGVector(dx: -1, dy: -1))
        #expect(opponent.nextPaddleY(current: 0.12, ball: ball, interval: 0.1) > 0.12)
    }

    @Test func farAwayBallIsOnlyRoughlyGuessed() {
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0)
        // Will arrive low (about 0.69), but it's still far off, so the computer follows where it is (0.2) for now.
        let ball = Ball(position: CGPoint(x: 1.5, y: 0.2), velocity: CGVector(dx: -1, dy: -1))
        #expect(opponent.nextPaddleY(current: 0.5, ball: ball, interval: 0.1) < 0.5)
    }

    @Test func swaysWhileWaitingForTheBall() {
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0)
        let away = Ball(position: CGPoint(x: 0.8, y: 0.5), velocity: CGVector(dx: 1, dy: 0))
        var positions: [CGFloat] = []
        var paddle: CGFloat = 0.5
        for _ in 0..<20 {
            paddle = opponent.nextPaddleY(current: paddle, ball: away, interval: 0.1)
            positions.append(paddle)
        }
        let spread = (positions.max() ?? 0) - (positions.min() ?? 0)
        #expect(spread > 0.03)
    }
}

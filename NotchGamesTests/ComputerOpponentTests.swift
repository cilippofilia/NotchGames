//
//  ComputerOpponentTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchGames

struct ComputerOpponentTests {
    private func incoming(atY height: CGFloat) -> Ball {
        Ball(position: CGPoint(x: 0.5, y: height), velocity: CGVector(dx: -1, dy: 0))
    }

    @Test func movesTowardIncomingBallButNoFasterThanMax() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(reactionDelay: 0)
        let next = opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.9),
            playerY: 0.5, interval: 0.1, using: &generator)
        #expect(next > 0.5)
        #expect(next - 0.5 <= opponent.maxSpeed * 0.1 + 0.0001)
    }

    @Test func returnsToCenterWhenBallMovesAway() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(reactionDelay: 0)
        let away = Ball(position: CGPoint(x: 0.5, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
        #expect(opponent.nextPaddleY(current: 0.2, ball: away,
            playerY: 0.5, interval: 0.1, using: &generator) > 0.2)
    }

    @Test func staysInsideCourt() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0)
        let next = opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 1.0),
            playerY: 0.5, interval: 1, using: &generator)
        #expect(next <= 1.0 - PongModel.paddleHeight / 2)
    }

    @Test func reactsToDelayedBallPosition() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0.2, deadZone: 0)
        _ = opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.2),
            playerY: 0.5, interval: 0.1, using: &generator)
        // Still chasing the older, lower reading.
        #expect(opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.8),
            playerY: 0.5, interval: 0.05, using: &generator) < 0.5)
    }

    @Test func holdsStillInsideDeadZone() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(reactionDelay: 0)
        #expect(opponent.nextPaddleY(current: 0.5, ball: incoming(atY: 0.51),
            playerY: 0.5, interval: 0.1, using: &generator) == 0.5)
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
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0)
        // Close to the paddle and above it, but about to bounce off the top wall and arrive lower.
        let ball = Ball(position: CGPoint(x: 0.25, y: 0.05), velocity: CGVector(dx: -1, dy: -1))
        #expect(opponent.nextPaddleY(current: 0.12, ball: ball,
            playerY: 0.5, interval: 0.1, using: &generator) > 0.12)
    }

    @Test func farAwayBallIsOnlyRoughlyGuessed() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0)
        // Will arrive low (about 0.69), but it's still far off, so the computer follows where it is (0.2) for now.
        let ball = Ball(position: CGPoint(x: 1.5, y: 0.2), velocity: CGVector(dx: -1, dy: -1))
        #expect(opponent.nextPaddleY(current: 0.5, ball: ball,
            playerY: 0.5, interval: 0.1, using: &generator) < 0.5)
    }

    @Test func swaysWhileWaitingForTheBall() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0)
        let away = Ball(position: CGPoint(x: 0.8, y: 0.5), velocity: CGVector(dx: 1, dy: 0))
        var positions: [CGFloat] = []
        var paddle: CGFloat = 0.5
        for _ in 0..<20 {
            paddle = opponent.nextPaddleY(current: paddle, ball: away,
            playerY: 0.5, interval: 0.1, using: &generator)
            positions.append(paddle)
        }
        let spread = (positions.max() ?? 0) - (positions.min() ?? 0)
        #expect(spread > 0.03)
    }

    @Test func skilledReturnIsAngledAwayFromThePlayer() {
        var generator = SystemRandomNumberGenerator()
        var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0, skill: 1)
        let ball = Ball(position: CGPoint(x: 0.1, y: 0.5), velocity: CGVector(dx: -1, dy: 0))
        // Player near the top: the paddle sits above the ball so it strikes low and sends the return down.
        #expect(opponent.nextPaddleY(current: 0.5, ball: ball, playerY: 0.2, interval: 0.1, using: &generator) < 0.48)
    }

    @Test func unskilledComputerPlaysEachShotDifferently() {
        var generator = SystemRandomNumberGenerator()
        let ball = Ball(position: CGPoint(x: 0.1, y: 0.5), velocity: CGVector(dx: -1, dy: 0))
        let spots = (0..<20).map { _ in
            var opponent = ComputerOpponent(maxSpeed: 100, reactionDelay: 0, deadZone: 0, skill: 0)
            return opponent.nextPaddleY(current: 0.5, ball: ball,
            playerY: 0.5, interval: 0.1, using: &generator)
        }
        #expect((spots.max() ?? 0) - (spots.min() ?? 0) > 0.02)
    }
}

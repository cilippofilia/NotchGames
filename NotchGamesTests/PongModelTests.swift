//
//  PongModelTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchGames

struct PongModelTests {
    @Test func ballBouncesOffTopWall() {
        var model = PongModel()
        model.ball = Ball(position: CGPoint(x: 0.8, y: 0.013), velocity: CGVector(dx: 0, dy: -1))
        model.step(by: 0.01)
        #expect(model.ball.velocity.dy > 0)
    }

    @Test func playerPaddleReturnsBall() {
        var model = PongModel()
        model.playerY = 0.5
        model.ball = Ball(position: CGPoint(x: 1.55, y: 0.5), velocity: CGVector(dx: 1, dy: 0))
        model.step(by: 0.02)
        #expect(model.ball.velocity.dx < 0)
    }

    @Test func computerPaddleReturnsBall() {
        var model = PongModel()
        model.computerY = 0.5
        model.ball = Ball(position: CGPoint(x: 0.05, y: 0.5), velocity: CGVector(dx: -1, dy: 0))
        model.step(by: 0.02)
        #expect(model.ball.velocity.dx > 0)
    }

    @Test func fastBallDoesNotTunnelThroughPaddle() {
        var model = PongModel()
        model.playerY = 0.5
        model.ball = Ball(position: CGPoint(x: 1.50, y: 0.5), velocity: CGVector(dx: 2.0, dy: 0))
        model.step(by: 1.0 / 30)
        #expect(model.ball.velocity.dx < 0)
    }

    @Test func missScoresForComputerAndReserves() {
        var model = PongModel()
        model.playerY = 0.1
        model.ball = Ball(position: CGPoint(x: 1.59, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
        model.step(by: 0.03)
        #expect(model.computerScore == 1)
        #expect(abs(model.ball.position.x - 0.8) < 0.05)
    }

    @Test func hugeTimeStepIsClamped() {
        var model = PongModel()
        let start = model.ball.position
        model.step(by: 5)
        #expect(abs(model.ball.position.x - start.x) <= PongModel.serveSpeed / 30 + 0.0001)
    }

    @Test func fifthPointWinsAndFreezes() {
        var model = PongModel()
        for _ in 0..<5 {
            model.playerY = 0.1
            model.computerY = 0.1
            model.ball = Ball(position: CGPoint(x: 0.01, y: 0.9), velocity: CGVector(dx: -1, dy: 0))
            model.step(by: 0.03)
        }
        #expect(model.winner == .player)
        let frozen = model.ball
        model.step(by: 0.03)
        #expect(model.ball == frozen)
    }

    @Test func speedCapsAtMax() {
        var model = PongModel()
        model.playerY = 0.5
        model.ball = Ball(position: CGPoint(x: 1.55, y: 0.5), velocity: CGVector(dx: 1.99, dy: 0))
        model.step(by: 0.02)
        #expect(hypot(model.ball.velocity.dx, model.ball.velocity.dy) <= PongModel.maxSpeed + 0.0001)
    }

    @Test func hittingNearThePaddleEdgeSendsTheBallAtAnAngle() {
        var model = PongModel()
        model.playerY = 0.5
        model.ball = Ball(position: CGPoint(x: 1.55, y: 0.6), velocity: CGVector(dx: 1, dy: 0))
        model.step(by: 0.02)
        #expect(model.ball.velocity.dy > 0)
    }
}

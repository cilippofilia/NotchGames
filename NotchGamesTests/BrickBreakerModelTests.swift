//
//  BrickBreakerModelTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Testing
@testable import NotchGames

struct BrickBreakerModelTests {
    typealias Model = BrickBreakerModel

    private func standingBricks(_ model: Model) -> Int {
        model.wall.rows.reduce(0) { $0 + $1.filter { $0 }.count }
    }

    /// A ball just below the paddle's line, heading for the bottom edge.
    private func missing(_ model: inout Model) {
        model.paddleX = 0.1
        model.ball = Ball(position: CGPoint(x: 0.6, y: 0.995), velocity: CGVector(dx: 0, dy: 0.7))
        model.step(by: 1.0 / 60)
    }

    @Test func ballBouncesOffSideAndTopWalls() {
        var model = Model()
        model.ball = Ball(position: CGPoint(x: 0.02, y: 0.02), velocity: CGVector(dx: -0.5, dy: -0.5))
        model.step(by: 1.0 / 60)
        #expect(model.ball.velocity.dx > 0)
        #expect(model.ball.velocity.dy > 0)
        #expect(model.wallBounce != nil)
    }

    @Test func paddleSendsTheBallBackUpAngledByHitPoint() {
        var model = Model()
        model.paddleX = 0.4
        model.ball = Ball(
            position: CGPoint(x: 0.45, y: Model.paddleTop - Model.ballRadius - 0.005),
            velocity: CGVector(dx: 0, dy: 0.7)
        )
        model.step(by: 1.0 / 60)
        #expect(model.ball.velocity.dy < 0)
        #expect(model.ball.velocity.dx > 0)
    }

    @Test func brickBreaksAndScoresByLevel() throws {
        var model = Model()
        let bottom = try #require(model.wall.lowestBrickBottom)
        let brick = model.wall.rect(row: model.wall.rows.count - 1, column: 4, courtWidth: Model.courtSize.width)
        model.ball = Ball(
            position: CGPoint(x: brick.midX, y: bottom + Model.ballRadius + 0.003),
            velocity: CGVector(dx: 0, dy: -0.7)
        )
        model.step(by: 1.0 / 60)
        #expect(standingBricks(model) == Model.startingRows * BrickWall.columns - 1)
        #expect(model.score == Model.brickPoints * model.level)
        #expect(model.ball.velocity.dy > 0)
        #expect(model.brokenBrick == brick)
    }

    @Test func fastBallCannotTunnelThroughABrick() throws {
        var model = Model()
        let brick = model.wall.rect(row: model.wall.rows.count - 1, column: 4, courtWidth: Model.courtSize.width)
        model.ball = Ball(
            position: CGPoint(x: brick.midX, y: brick.maxY + Model.ballRadius + 0.001),
            velocity: CGVector(dx: 0, dy: -Model.maxBallSpeed)
        )
        model.step(by: MatchClock.maxStep)
        #expect(standingBricks(model) == Model.startingRows * BrickWall.columns - 1)
        #expect(model.ball.velocity.dy > 0)
    }

    @Test func fastBallCannotTunnelThroughThePaddle() {
        var model = Model()
        model.paddleX = 0.4
        model.ball = Ball(
            position: CGPoint(x: 0.4, y: Model.paddleTop - Model.ballRadius - 0.001),
            velocity: CGVector(dx: 0, dy: Model.maxBallSpeed)
        )
        model.step(by: MatchClock.maxStep)
        #expect(model.ball.velocity.dy < 0)
        #expect(model.lives == Model.startingLives)
    }

    @Test func missedBallCostsALife() {
        var model = Model()
        missing(&model)
        #expect(model.lives == Model.startingLives - 1)
        #expect(model.lostBall)
        #expect(!model.isOver)
    }

    @Test func thirdMissEndsTheRun() {
        var model = Model()
        for _ in 0..<3 { missing(&model) }
        #expect(model.isOver)
        #expect(model.lives == 0)
        let ended = model.ball
        model.step(by: 1.0 / 60)
        #expect(model.ball == ended)
    }

    @Test func rowDropAddsPointsAndLevelsUp() {
        var model = Model()
        for _ in 0..<5 { model.dropRow() }
        #expect(model.rowsDropped == 5)
        #expect(model.level == 2)
        #expect(model.score == 5 * Model.rowPoints)
        #expect(model.rowInterval == Model.baseRowInterval - Model.rowIntervalPerLevel)
        #expect(model.ballSpeed == Model.baseBallSpeed + Model.ballSpeedPerLevel)
    }

    @Test func rowIntervalAndSpeedAreCapped() {
        let model = Model(rowsDropped: 500)
        #expect(model.rowInterval == Model.minRowInterval)
        #expect(model.ballSpeed == Model.maxBallSpeed)
    }

    @Test func wallReachingThePaddleEndsTheRun() throws {
        var model = Model()
        model.ball = Ball(position: CGPoint(x: 0.4, y: 0.96), velocity: .zero)
        for _ in 0..<100 where !model.isOver { model.dropRow() }
        #expect(model.isOver)
        let bottom = try #require(model.wall.lowestBrickBottom)
        #expect(bottom > Model.paddleTop - 2 * Model.ballRadius)
    }

    @Test func rowDroppingOnTheBallPushesItBelow() throws {
        var model = Model()
        let velocity = CGVector(dx: 0.3, dy: -0.5)
        let lowest = model.wall.rect(row: model.wall.rows.count - 1, column: 4, courtWidth: Model.courtSize.width)
        let inside = CGPoint(x: lowest.midX, y: lowest.maxY + Model.ballRadius - 0.002)
        model.ball = Ball(position: inside, velocity: velocity)
        model.dropRow()
        let bottom = try #require(model.wall.lowestBrickBottom)
        #expect(model.ball.position.y - Model.ballRadius >= bottom)
        #expect(model.ball.velocity == velocity)
    }

    @Test func rowDropNeverCostsALife() throws {
        var model = Model()
        // 15 rows, so the next drop lands the wall just above the paddle.
        for _ in 0..<12 { model.dropRow() }
        let lowest = model.wall.rect(row: model.wall.rows.count - 1, column: 4, courtWidth: Model.courtSize.width)
        model.paddleX = lowest.midX
        model.ball = Ball(
            position: CGPoint(x: lowest.midX, y: lowest.maxY + Model.ballRadius + 0.003),
            velocity: CGVector(dx: 0, dy: 0.7)
        )
        model.dropRow()
        for _ in 0..<30 { model.step(by: 1.0 / 60) }
        #expect(model.lives == Model.startingLives)
    }

    @Test func courtReachesThePanelSidesAndKeepsItsShape() {
        let panel = PullSizing.bodySize(forPull: 900, shape: GameKind.brickBreaker.panelShape)
        let court = CourtLayout.rect(in: panel, sideInset: CourtLayout.edgeInset)
        #expect(court.minX == CourtLayout.edgeInset)
        // Drawn at (nearly) the model's own shape, so the ball isn't squashed against the bricks.
        #expect(abs(court.width / court.height - Model.courtSize.width) < 0.02)
    }

    @Test func paddleSideSendsTheBallBackUp() {
        var model = Model()
        model.paddleX = 0.4
        let left = 0.4 - Model.paddleWidth / 2
        model.ball = Ball(
            position: CGPoint(x: left - Model.ballRadius - 0.002, y: Model.paddleTop + Model.paddleHeight / 2),
            velocity: CGVector(dx: 0.7, dy: 0.1)
        )
        model.step(by: 1.0 / 60)
        #expect(model.ball.velocity.dy < 0)
        #expect(model.ball.velocity.dx < 0)
        #expect(model.ball.position.y + Model.ballRadius <= Model.paddleTop)
    }

    @Test func paddleSweptIntoTheBallSendsItBackUp() {
        var model = Model()
        model.ball = Ball(position: CGPoint(x: 0.4, y: Model.paddleTop + 0.005), velocity: CGVector(dx: 0, dy: 0.7))
        model.paddleX = 0.4 + Model.paddleWidth / 2
        model.step(by: 1.0 / 60)
        #expect(model.ball.velocity.dy < 0)
        #expect(model.lives == Model.startingLives)
    }

    // MARK: - Power-ups

    @Test func paddleCatchesAPowerUp() {
        var model = Model()
        model.paddleX = 0.4
        model.powerUps = [PowerUp(kind: .bomb, position: CGPoint(x: 0.4, y: Model.paddleTop - 0.005))]
        model.step(by: 1.0 / 60)
        #expect(model.powerUps.isEmpty)
        #expect(model.bombHitsLeft == Model.bombHits)
    }

    @Test func missedPowerUpFallsAway() {
        var model = Model()
        model.paddleX = 0.1
        model.powerUps = [PowerUp(kind: .bomb, position: CGPoint(x: 0.6, y: 0.995 + PowerUp.size.height))]
        model.step(by: 1.0 / 60)
        #expect(model.powerUps.isEmpty)
        #expect(model.bombHitsLeft == 0)
    }

    @Test func lostExtraBallCostsNoLife() {
        var model = Model()
        model.paddleX = 0.1
        model.extraBalls = [Ball(position: CGPoint(x: 0.6, y: 0.995), velocity: CGVector(dx: 0, dy: 0.7))]
        model.step(by: 1.0 / 60)
        #expect(model.extraBalls.isEmpty)
        #expect(model.lives == Model.startingLives)
        #expect(!model.lostBall)
    }

    @Test func multiBallLaunchesTwoBalls() {
        var model = Model()
        model.activate(.multiBall)
        #expect(model.extraBalls.count == 2)
        #expect(model.extraBalls.allSatisfy { $0.velocity.dy < 0 })
    }

    @Test func losingThePinkBallClearsBonuses() {
        var model = Model()
        model.activate(.multiBall)
        model.activate(.bomb)
        model.activate(.slowdown)
        missing(&model)
        #expect(model.extraBalls.isEmpty)
        #expect(model.bombHitsLeft == 0)
        #expect(model.slowTimeLeft == 0)
    }

    @Test func bombBreaksNeighborsForThreeHits() throws {
        var model = Model()
        model.powerUpChance = 0
        model.activate(.bomb)
        let before = standingBricks(model)
        let bottom = try #require(model.wall.lowestBrickBottom)
        let brick = model.wall.rect(row: model.wall.rows.count - 1, column: 4, courtWidth: Model.courtSize.width)
        model.ball = Ball(
            position: CGPoint(x: brick.midX, y: bottom + Model.ballRadius + 0.003),
            velocity: CGVector(dx: 0, dy: -0.7)
        )
        model.step(by: 1.0 / 60)
        // The hit brick, two beside it, and three in the row above.
        #expect(standingBricks(model) == before - 6)
        #expect(model.bombHitsLeft == Model.bombHits - 1)
    }

    @Test func slowdownSlowsThenWearsOff() {
        var model = Model()
        let normal = model.ballSpeed
        model.activate(.slowdown)
        #expect(model.ballSpeed == normal * Model.slowFactor)
        #expect(abs(hypot(model.ball.velocity.dx, model.ball.velocity.dy) - model.ballSpeed) < 0.0001)
        model.slowTimeLeft = 0.001
        model.ball = Ball(position: CGPoint(x: 0.4, y: 0.6), velocity: CGVector(dx: 0, dy: 0.1))
        model.step(by: 1.0 / 60)
        #expect(model.ballSpeed == normal)
        #expect(abs(hypot(model.ball.velocity.dx, model.ball.velocity.dy) - normal) < 0.0001)
    }

    @Test func brickCanDropAPowerUp() throws {
        var model = Model()
        model.powerUpChance = 1
        let bottom = try #require(model.wall.lowestBrickBottom)
        let brick = model.wall.rect(row: model.wall.rows.count - 1, column: 4, courtWidth: Model.courtSize.width)
        model.ball = Ball(
            position: CGPoint(x: brick.midX, y: bottom + Model.ballRadius + 0.003),
            velocity: CGVector(dx: 0, dy: -0.7)
        )
        model.step(by: 1.0 / 60)
        #expect(model.powerUps.count == 1)
    }
}

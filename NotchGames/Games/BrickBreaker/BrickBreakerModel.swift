//
//  BrickBreakerModel.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation

/// Brick breaker rules and physics in court units: 0.8 wide, 1.0 tall, origin top-left, y down.
/// Endless: rows keep dropping in from the top, faster each level, until the lives run out or the wall lands.
nonisolated struct BrickBreakerModel {
    static let courtSize = CGSize(width: 0.8, height: 1.0)
    static let paddleWidth: CGFloat = 0.18
    /// Court y of the paddle's top edge, which the ball bounces off.
    static let paddleTop: CGFloat = 0.92
    static let paddleHeight: CGFloat = 0.02
    static let ballRadius: CGFloat = 0.014
    static let startingLives = 3
    static let startingRows = 3
    static let rowsPerLevel = 5
    // Starting values, tuned by playing.
    static let baseBallSpeed: CGFloat = 0.6
    static let ballSpeedPerLevel: CGFloat = 0.08
    static let maxBallSpeed: CGFloat = 1.5
    static let baseRowInterval: TimeInterval = 10
    static let rowIntervalPerLevel: TimeInterval = 0.8
    static let minRowInterval: TimeInterval = 3
    static let brickPoints = 10
    static let rowPoints = 25
    /// Odds that a broken brick drops a power-up.
    static let powerUpChance = 0.1
    static let extraBallAngle: CGFloat = 0.5
    /// Bricks a bomb power-up blasts through, each also breaking its eight neighbors.
    static let bombHits = 3
    static let slowFactor: CGFloat = 0.6
    static let slowDuration: TimeInterval = 8
    private static let maxBounceAngle: CGFloat = .pi / 3
    private static let serveAngle: CGFloat = 0.3

    /// The pink ball: losing it costs a life.
    var ball = Ball(position: .zero, velocity: .zero)
    /// Yellow balls from the multi-ball power-up; they fall away without costing anything.
    var extraBalls: [Ball] = []
    var powerUps: [PowerUp] = []
    /// Brick hits left that also blast the neighbors.
    var bombHitsLeft = 0
    var slowTimeLeft: TimeInterval = 0
    /// Overridable so tests can force or prevent drops.
    var powerUpChance = BrickBreakerModel.powerUpChance
    /// The paddle's center.
    var paddleX = courtSize.width / 2
    private(set) var wall = BrickWall(rows: startingRows)
    private(set) var lives = startingLives
    private(set) var score = 0
    private(set) var rowsDropped: Int
    private(set) var isOver = false
    /// Where the ball touched a wall during the last step, and which way is back into the court.
    private(set) var wallBounce: (position: CGPoint, inward: CGVector)?
    /// The brick broken during the last step, for its spark.
    private(set) var brokenBrick: CGRect?
    /// True for the step in which the ball got past the paddle.
    private(set) var lostBall = false

    var paddleRect: CGRect {
        CGRect(x: paddleX - Self.paddleWidth / 2, y: Self.paddleTop, width: Self.paddleWidth, height: Self.paddleHeight)
    }

    var level: Int { 1 + rowsDropped / Self.rowsPerLevel }

    var ballSpeed: CGFloat {
        min(Self.baseBallSpeed + CGFloat(level - 1) * Self.ballSpeedPerLevel, Self.maxBallSpeed)
            * (slowTimeLeft > 0 ? Self.slowFactor : 1)
    }

    var rowInterval: TimeInterval {
        max(Self.baseRowInterval - Double(level - 1) * Self.rowIntervalPerLevel, Self.minRowInterval)
    }

    /// `rowsDropped` lets tests start at a later level.
    init(rowsDropped: Int = 0) {
        self.rowsDropped = rowsDropped
        serve()
    }

    /// Keeps the paddle inside the court.
    static func clampedPaddleX(_ center: CGFloat) -> CGFloat {
        min(max(center, paddleWidth / 2), courtSize.width - paddleWidth / 2)
    }

    mutating func step(by interval: TimeInterval) {
        wallBounce = nil
        brokenBrick = nil
        lostBall = false
        guard !isOver else { return }
        let time = CGFloat(min(interval, MatchClock.maxStep))
        let distance = hypot(ball.velocity.dx, ball.velocity.dy) * time
        // Small enough slices that the ball never moves past a brick or the paddle in one of them.
        let slices = max(Int((distance / Self.ballRadius).rounded(.up)), 1)
        let slice = time / CGFloat(slices)
        for _ in 0..<slices {
            // Moved through locals: helpers mutate both the ball and the wall.
            var main = ball
            let mainLost = advance(&main, by: slice)
            ball = main
            var kept: [Ball] = []
            for var extra in extraBalls {
                if !advance(&extra, by: slice) { kept.append(extra) }
            }
            extraBalls = kept
            if mainLost {
                loseBall()
                return
            }
        }
        movePowerUps(by: time)
        if slowTimeLeft > 0 {
            slowTimeLeft = max(slowTimeLeft - TimeInterval(time), 0)
            if slowTimeLeft == 0 { matchBallToSpeed() }
        }
    }

    /// A new full row arrives at the top, pushing the wall down. Ends the run once the wall reaches the paddle.
    mutating func dropRow() {
        guard !isOver else { return }
        let levelBefore = level
        wall.dropRow()
        rowsDropped += 1
        score += Self.rowPoints
        if level != levelBefore { matchBallToSpeed() }
        pushOutOfWall(&ball)
        for index in extraBalls.indices { pushOutOfWall(&extraBalls[index]) }
        // The wall has reached the paddle once there's no room left for the ball between them,
        // so a row can never push the ball through the paddle and cost a life.
        if let bottom = wall.lowestBrickBottom, bottom > Self.paddleTop - 2 * Self.ballRadius {
            end()
        }
    }

    mutating func addSurvivalPoints(_ points: Int) {
        guard !isOver else { return }
        score += points
    }

    /// The ball just above the paddle's center, heading up and slightly right.
    mutating func serve() {
        ball = Ball(
            position: CGPoint(x: paddleX, y: Self.paddleTop - Self.ballRadius - 0.01),
            velocity: CGVector(dx: ballSpeed * sin(Self.serveAngle), dy: -ballSpeed * cos(Self.serveAngle))
        )
    }

    // MARK: - Private

    /// Moves one ball one slice; true once it has left the bottom of the court, like the goal line in Pong.
    private mutating func advance(_ ball: inout Ball, by time: CGFloat) -> Bool {
        ball.position.x += ball.velocity.dx * time
        ball.position.y += ball.velocity.dy * time
        bounceOffWalls(&ball)
        breakFirstHitBrick(&ball)
        bounceOffPaddle(&ball)
        return ball.position.y > Self.courtSize.height
    }

    /// Falls the capsules; the paddle catches any that touch it, and the rest drop out of the court.
    private mutating func movePowerUps(by time: CGFloat) {
        let paddle = paddleRect
        var falling: [PowerUp] = []
        for var powerUp in powerUps {
            powerUp.position.y += PowerUp.fallSpeed * time
            if powerUp.rect.intersects(paddle) {
                activate(powerUp.kind)
            } else if powerUp.rect.minY <= Self.courtSize.height {
                falling.append(powerUp)
            }
        }
        powerUps = falling
    }

    mutating func activate(_ kind: PowerUp.Kind) {
        switch kind {
        case .multiBall:
            let start = CGPoint(x: paddleX, y: Self.paddleTop - Self.ballRadius - 0.01)
            for angle in [-Self.extraBallAngle, Self.extraBallAngle] {
                extraBalls.append(Ball(
                    position: start,
                    velocity: CGVector(dx: ballSpeed * sin(angle), dy: -ballSpeed * cos(angle))
                ))
            }
        case .bomb:
            bombHitsLeft = Self.bombHits
        case .slowdown:
            slowTimeLeft = Self.slowDuration
            matchBallToSpeed()
        }
    }

    private mutating func bounceOffWalls(_ ball: inout Ball) {
        let radius = Self.ballRadius
        if ball.position.x < radius {
            ball.position.x = 2 * radius - ball.position.x
            ball.velocity.dx = abs(ball.velocity.dx)
            wallBounce = (CGPoint(x: 0, y: ball.position.y), CGVector(dx: 1, dy: 0))
        } else if ball.position.x > Self.courtSize.width - radius {
            ball.position.x = 2 * (Self.courtSize.width - radius) - ball.position.x
            ball.velocity.dx = -abs(ball.velocity.dx)
            wallBounce = (CGPoint(x: Self.courtSize.width, y: ball.position.y), CGVector(dx: -1, dy: 0))
        }
        if ball.position.y < radius {
            ball.position.y = 2 * radius - ball.position.y
            ball.velocity.dy = abs(ball.velocity.dy)
            wallBounce = (CGPoint(x: ball.position.x, y: 0), CGVector(dx: 0, dy: 1))
        }
    }

    /// Breaks at most one brick per slice and bounces off it, so every slice still collides.
    private mutating func breakFirstHitBrick(_ ball: inout Ball) {
        for row in wall.rows.indices {
            for column in wall.rows[row].indices where wall.rows[row][column] {
                let brick = wall.rect(row: row, column: column, courtWidth: Self.courtSize.width)
                guard overlaps(brick, ball) else { continue }
                if bombHitsLeft > 0 {
                    bombHitsLeft -= 1
                    // Neighbors first: breaking the center can trim emptied rows off the bottom.
                    for neighborRow in row - 1...row + 1 {
                        for neighborColumn in column - 1...column + 1
                        where (neighborRow, neighborColumn) != (row, column) {
                            breakScoring(row: neighborRow, column: neighborColumn)
                        }
                    }
                }
                breakScoring(row: row, column: column)
                brokenBrick = brick
                bounce(&ball, off: brick)
                return
            }
        }
    }

    /// Breaks a standing brick for points, sometimes dropping a power-up. Off-wall or broken spots do nothing.
    private mutating func breakScoring(row: Int, column: Int) {
        guard wall.rows.indices.contains(row),
              wall.rows[row].indices.contains(column),
              wall.rows[row][column]
        else { return }
        let brick = wall.rect(row: row, column: column, courtWidth: Self.courtSize.width)
        wall.breakBrick(row: row, column: column)
        score += Self.brickPoints * level
        if Double.random(in: 0..<1) < powerUpChance, let kind = PowerUp.Kind.allCases.randomElement() {
            powerUps.append(PowerUp(kind: kind, position: CGPoint(x: brick.midX, y: brick.midY)))
        }
    }

    private func closestPoint(on rect: CGRect, _ ball: Ball) -> CGPoint {
        CGPoint(
            x: min(max(ball.position.x, rect.minX), rect.maxX),
            y: min(max(ball.position.y, rect.minY), rect.maxY)
        )
    }

    private func overlaps(_ rect: CGRect, _ ball: Ball) -> Bool {
        let closest = closestPoint(on: rect, ball)
        return hypot(ball.position.x - closest.x, ball.position.y - closest.y) < Self.ballRadius
    }

    /// Reflects off the point of contact, so faces bounce straight and corners bounce at an angle.
    private func bounce(_ ball: inout Ball, off brick: CGRect) {
        let closest = closestPoint(on: brick, ball)
        var normal = CGVector(dx: ball.position.x - closest.x, dy: ball.position.y - closest.y)
        var length = hypot(normal.dx, normal.dy)
        if length == 0 {
            // Center already inside the brick: push back out the way it came.
            normal = CGVector(dx: -ball.velocity.dx, dy: -ball.velocity.dy)
            length = hypot(normal.dx, normal.dy)
            guard length > 0 else { return }
        }
        normal = CGVector(dx: normal.dx / length, dy: normal.dy / length)
        let along = ball.velocity.dx * normal.dx + ball.velocity.dy * normal.dy
        if along < 0 {
            ball.velocity = CGVector(
                dx: ball.velocity.dx - 2 * along * normal.dx,
                dy: ball.velocity.dy - 2 * along * normal.dy
            )
        }
        ball.position = CGPoint(x: closest.x + normal.dx * Self.ballRadius, y: closest.y + normal.dy * Self.ballRadius)
    }

    /// The whole paddle is solid: touching the top, a side or a corner sends a falling ball back up,
    /// angled by how far from the paddle's center it landed, as in Pong.
    private func bounceOffPaddle(_ ball: inout Ball) {
        guard ball.velocity.dy > 0, overlaps(paddleRect, ball) else { return }
        // Lifted onto the paddle so a side hit can't leave it inside and bounce again.
        ball.position.y = Self.paddleTop - Self.ballRadius
        let offset = min(max((ball.position.x - paddleX) / (Self.paddleWidth / 2), -1), 1)
        let angle = offset * Self.maxBounceAngle
        ball.velocity = CGVector(dx: ballSpeed * sin(angle), dy: -ballSpeed * cos(angle))
    }

    private mutating func loseBall() {
        lives -= 1
        lostBall = true
        clearPowerUps()
        if lives <= 0 {
            end()
        } else {
            serve()
        }
    }

    private mutating func end() {
        isOver = true
        ball.velocity = .zero
        clearPowerUps()
    }

    /// A lost life or the end of the run takes every bonus with it.
    private mutating func clearPowerUps() {
        extraBalls = []
        powerUps = []
        bombHitsLeft = 0
        slowTimeLeft = 0
    }

    /// A new level or a slowdown changes every ball's speed mid-flight, keeping its direction.
    private mutating func matchBallToSpeed() {
        let speed = ballSpeed
        func rescale(_ ball: inout Ball) {
            let current = hypot(ball.velocity.dx, ball.velocity.dy)
            guard current > 0 else { return }
            ball.velocity = CGVector(dx: ball.velocity.dx * speed / current, dy: ball.velocity.dy * speed / current)
        }
        rescale(&ball)
        for index in extraBalls.indices { rescale(&extraBalls[index]) }
    }

    /// A row landing on the ball pushes it down below whatever it now overlaps; it never breaks bricks.
    private func pushOutOfWall(_ ball: inout Ball) {
        var moved = true
        while moved {
            moved = false
            for row in wall.rows.indices {
                for column in wall.rows[row].indices where wall.rows[row][column] {
                    let brick = wall.rect(row: row, column: column, courtWidth: Self.courtSize.width)
                    if overlaps(brick, ball) {
                        ball.position.y = brick.maxY + Self.ballRadius + 0.001
                        moved = true
                    }
                }
            }
        }
    }
}

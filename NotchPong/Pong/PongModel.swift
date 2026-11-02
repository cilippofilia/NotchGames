//
//  PongModel.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// Pong rules and physics in court units: 1.6 wide, 1.0 tall, origin top-left, y down.
nonisolated struct PongModel {
    static let courtSize = CGSize(width: 1.6, height: 1.0)
    static let paddleHeight: CGFloat = 0.22
    /// Distance of each paddle's face from its side of the court.
    static let paddleInset: CGFloat = 0.04
    static let ballRadius: CGFloat = 0.012
    static let serveSpeed: CGFloat = 0.9
    static let speedUpPerHit: CGFloat = 1.05
    static let maxSpeed: CGFloat = 2.0
    static let winningScore = 5
    /// Longest step simulated at once, so a late frame can't teleport the ball.
    static let maxStep: TimeInterval = 1.0 / 30
    private static let maxBounceAngle: CGFloat = .pi / 3

    var ball: Ball
    /// Paddle centers.
    var playerY: CGFloat = 0.5
    var computerY: CGFloat = 0.5
    private(set) var playerScore = 0
    private(set) var computerScore = 0
    private(set) var winner: PongSide?
    private var serveAngle: CGFloat

    init(serveToward side: PongSide = .player, serveAngle: CGFloat = 0.3) {
        self.serveAngle = serveAngle
        ball = Ball(position: .zero, velocity: .zero)
        serve(toward: side)
    }

    mutating func step(by interval: TimeInterval) {
        guard winner == nil else { return }
        let time = CGFloat(min(interval, Self.maxStep))
        let start = ball.position
        var end = CGPoint(x: start.x + ball.velocity.dx * time, y: start.y + ball.velocity.dy * time)

        let top = Self.ballRadius
        let bottom = Self.courtSize.height - Self.ballRadius
        if end.y < top {
            end.y = 2 * top - end.y
            ball.velocity.dy = abs(ball.velocity.dy)
        } else if end.y > bottom {
            end.y = 2 * bottom - end.y
            ball.velocity.dy = -abs(ball.velocity.dy)
        }

        let playerFace = Self.courtSize.width - Self.paddleInset
        let computerFace = Self.paddleInset
        if ball.velocity.dx > 0, start.x <= playerFace, end.x > playerFace {
            let hitY = crossingY(from: start, to: end, faceX: playerFace)
            if hits(paddleAt: playerY, hitY: hitY) {
                end.x = 2 * playerFace - end.x
                bounce(off: playerY, at: hitY, direction: -1)
            }
        } else if ball.velocity.dx < 0, start.x >= computerFace, end.x < computerFace {
            let hitY = crossingY(from: start, to: end, faceX: computerFace)
            if hits(paddleAt: computerY, hitY: hitY) {
                end.x = 2 * computerFace - end.x
                bounce(off: computerY, at: hitY, direction: 1)
            }
        }
        ball.position = end

        if end.x > Self.courtSize.width {
            score(for: .computer)
        } else if end.x < 0 {
            score(for: .player)
        }
    }

    /// Where the ball will be when it reaches `faceX`, folding its path off the top and bottom walls.
    static func arrivalY(of ball: Ball, atX faceX: CGFloat) -> CGFloat {
        guard ball.velocity.dx != 0 else { return ball.position.y }
        let time = max((faceX - ball.position.x) / ball.velocity.dx, 0)
        let unbounded = ball.position.y + ball.velocity.dy * time
        let low = ballRadius
        let span = courtSize.height - 2 * ballRadius
        // Each wall bounce mirrors the path, so fold the straight-line position back into the court.
        var folded = (unbounded - low).truncatingRemainder(dividingBy: 2 * span)
        if folded < 0 { folded += 2 * span }
        return low + (folded <= span ? folded : 2 * span - folded)
    }

    // MARK: - Private

    /// Where the ball's path crosses the paddle's face, so a fast ball can't skip past it in one step.
    private func crossingY(from start: CGPoint, to end: CGPoint, faceX: CGFloat) -> CGFloat {
        let progress = (faceX - start.x) / (end.x - start.x)
        return start.y + (end.y - start.y) * progress
    }

    private func hits(paddleAt paddleY: CGFloat, hitY: CGFloat) -> Bool {
        abs(hitY - paddleY) <= Self.paddleHeight / 2 + Self.ballRadius
    }

    /// Sends the ball back faster, angled by how far from the paddle's center it hit.
    private mutating func bounce(off paddleY: CGFloat, at hitY: CGFloat, direction: CGFloat) {
        let offset = min(max((hitY - paddleY) / (Self.paddleHeight / 2), -1), 1)
        let angle = offset * Self.maxBounceAngle
        let speed = min(hypot(ball.velocity.dx, ball.velocity.dy) * Self.speedUpPerHit, Self.maxSpeed)
        ball.velocity = CGVector(dx: direction * speed * cos(angle), dy: speed * sin(angle))
    }

    private mutating func score(for side: PongSide) {
        switch side {
        case .player: playerScore += 1
        case .computer: computerScore += 1
        }
        if max(playerScore, computerScore) >= Self.winningScore {
            winner = side
            ball.velocity = .zero
            return
        }
        // The side that conceded receives the next serve.
        serve(toward: side == .player ? .computer : .player)
    }

    /// Puts the ball in the middle and sends it off, alternating up and down each serve.
    private mutating func serve(toward side: PongSide) {
        let direction: CGFloat = side == .player ? 1 : -1
        ball.position = CGPoint(x: Self.courtSize.width / 2, y: Self.courtSize.height / 2)
        ball.velocity = CGVector(
            dx: direction * Self.serveSpeed * cos(serveAngle),
            dy: Self.serveSpeed * sin(serveAngle)
        )
        serveAngle = -serveAngle
    }
}

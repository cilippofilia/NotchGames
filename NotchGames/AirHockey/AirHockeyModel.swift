//
//  AirHockeyModel.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// Air hockey rules and physics in court units: 1.6 wide, 1.0 tall, origin top-left, y down.
/// The player's mallet works the right half and defends the right goal; the computer's the left.
nonisolated struct AirHockeyModel {
    static let courtSize = PongModel.courtSize
    static let puckRadius: CGFloat = 0.035
    static let malletRadius: CGFloat = 0.06
    /// Half the height of each goal opening, centered on its back wall.
    static let goalHalfHeight: CGFloat = 0.17
    static let maxPuckSpeed: CGFloat = 2.4
    /// How much speed a puck keeps when struck by a mallet.
    static let restitution: CGFloat = 0.9
    /// Share of its speed a free puck keeps after one second of sliding.
    static let friction: CGFloat = 0.7
    /// How fast the player's mallet can chase the pointer.
    static let playerMalletSpeed: CGFloat = 5
    static let winningScore = 5
    /// Collisions are checked this many times per step, so a fast mallet can't pass through the puck.
    private static let substeps = 8

    var puck = Ball(position: CGPoint(x: courtSize.width / 2, y: courtSize.height / 2), velocity: .zero)
    var playerMallet = CGPoint(x: courtSize.width * 0.8, y: courtSize.height / 2)
    var computerMallet = CGPoint(x: courtSize.width * 0.2, y: courtSize.height / 2)
    private(set) var playerScore = 0
    private(set) var computerScore = 0
    private(set) var winner: PongSide?
    /// Where the puck touched a wall during the last step, and which way is back into the court.
    private(set) var wallBounce: (position: CGPoint, inward: CGVector)?

    mutating func step(
        by interval: TimeInterval,
        playerTarget: CGPoint,
        computerTarget: CGPoint,
        computerSpeed: CGFloat
    ) {
        guard winner == nil else { return }
        wallBounce = nil
        let time = CGFloat(min(interval, MatchClock.maxStep))
        guard time > 0 else { return }

        let playerStart = playerMallet
        let computerStart = computerMallet
        let playerEnd = Self.move(playerStart, toward: Self.clamped(playerTarget, for: .player),
                                  maxDistance: Self.playerMalletSpeed * time)
        let computerEnd = Self.move(computerStart, toward: Self.clamped(computerTarget, for: .computer),
                                    maxDistance: computerSpeed * time)
        let playerVelocity = Self.velocity(from: playerStart, to: playerEnd, over: time)
        let computerVelocity = Self.velocity(from: computerStart, to: computerEnd, over: time)

        let slice = time / CGFloat(Self.substeps)
        for index in 1...Self.substeps {
            let progress = CGFloat(index) / CGFloat(Self.substeps)
            playerMallet = Self.lerp(playerStart, playerEnd, progress)
            computerMallet = Self.lerp(computerStart, computerEnd, progress)
            puck.position.x += puck.velocity.dx * slice
            puck.position.y += puck.velocity.dy * slice
            strike(from: playerMallet, moving: playerVelocity)
            strike(from: computerMallet, moving: computerVelocity)
            if let scorer = bounceOffWalls() {
                score(for: scorer)
                return
            }
        }

        let keep = pow(Self.friction, time)
        puck.velocity = CGVector(dx: puck.velocity.dx * keep, dy: puck.velocity.dy * keep)
        capPuckSpeed()
    }

    // MARK: - Private

    /// Pushes the puck out of a mallet it overlaps and, if they're closing, bounces it off the moving mallet.
    private mutating func strike(from mallet: CGPoint, moving malletVelocity: CGVector) {
        let gap = CGVector(dx: puck.position.x - mallet.x, dy: puck.position.y - mallet.y)
        let distance = hypot(gap.dx, gap.dy)
        let reach = Self.malletRadius + Self.puckRadius
        guard distance < reach else { return }
        let normal = distance > 0 ? CGVector(dx: gap.dx / distance, dy: gap.dy / distance) : CGVector(dx: 1, dy: 0)
        puck.position = CGPoint(x: mallet.x + normal.dx * reach, y: mallet.y + normal.dy * reach)
        let closing = (puck.velocity.dx - malletVelocity.dx) * normal.dx
            + (puck.velocity.dy - malletVelocity.dy) * normal.dy
        guard closing < 0 else { return }
        let push = (1 + Self.restitution) * closing
        puck.velocity = CGVector(dx: puck.velocity.dx - push * normal.dx, dy: puck.velocity.dy - push * normal.dy)
        capPuckSpeed()
    }

    /// Bounces the puck off the walls, except through the goal openings. Returns who scored, if anyone did.
    private mutating func bounceOffWalls() -> PongSide? {
        let radius = Self.puckRadius
        let width = Self.courtSize.width
        let height = Self.courtSize.height
        if puck.position.y < radius {
            puck.position.y = 2 * radius - puck.position.y
            puck.velocity.dy = abs(puck.velocity.dy)
            wallBounce = (CGPoint(x: puck.position.x, y: 0), CGVector(dx: 0, dy: 1))
        } else if puck.position.y > height - radius {
            puck.position.y = 2 * (height - radius) - puck.position.y
            puck.velocity.dy = -abs(puck.velocity.dy)
            wallBounce = (CGPoint(x: puck.position.x, y: height), CGVector(dx: 0, dy: -1))
        }

        let inGoalMouth = abs(puck.position.y - height / 2) < Self.goalHalfHeight
        if inGoalMouth {
            if puck.position.x < 0 { return .player }
            if puck.position.x > width { return .computer }
        } else if puck.position.x < radius {
            puck.position.x = 2 * radius - puck.position.x
            puck.velocity.dx = abs(puck.velocity.dx)
            wallBounce = (CGPoint(x: 0, y: puck.position.y), CGVector(dx: 1, dy: 0))
        } else if puck.position.x > width - radius {
            puck.position.x = 2 * (width - radius) - puck.position.x
            puck.velocity.dx = -abs(puck.velocity.dx)
            wallBounce = (CGPoint(x: width, y: puck.position.y), CGVector(dx: -1, dy: 0))
        }
        return nil
    }

    private mutating func score(for side: PongSide) {
        switch side {
        case .player: playerScore += 1
        case .computer: computerScore += 1
        }
        if max(playerScore, computerScore) >= Self.winningScore { winner = side }
        // The side that conceded gets the puck, still, in the middle of its half.
        let receiverX = side == .player ? Self.courtSize.width * 0.25 : Self.courtSize.width * 0.75
        puck = Ball(position: CGPoint(x: receiverX, y: Self.courtSize.height / 2), velocity: .zero)
    }

    private mutating func capPuckSpeed() {
        let speed = hypot(puck.velocity.dx, puck.velocity.dy)
        guard speed > Self.maxPuckSpeed else { return }
        let scale = Self.maxPuckSpeed / speed
        puck.velocity = CGVector(dx: puck.velocity.dx * scale, dy: puck.velocity.dy * scale)
    }

    /// Keeps a mallet inside its own half of the court.
    static func clamped(_ point: CGPoint, for side: PongSide) -> CGPoint {
        let radius = malletRadius
        let middle = courtSize.width / 2
        let minX = side == .player ? middle + radius : radius
        let maxX = side == .player ? courtSize.width - radius : middle - radius
        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, radius), courtSize.height - radius)
        )
    }

    private static func move(_ point: CGPoint, toward target: CGPoint, maxDistance: CGFloat) -> CGPoint {
        let distance = hypot(target.x - point.x, target.y - point.y)
        guard distance > maxDistance, distance > 0 else { return target }
        let share = maxDistance / distance
        return CGPoint(x: point.x + (target.x - point.x) * share, y: point.y + (target.y - point.y) * share)
    }

    private static func velocity(from start: CGPoint, to end: CGPoint, over time: CGFloat) -> CGVector {
        CGVector(dx: (end.x - start.x) / time, dy: (end.y - start.y) / time)
    }

    private static func lerp(_ start: CGPoint, _ end: CGPoint, _ amount: CGFloat) -> CGPoint {
        CGPoint(x: start.x + (end.x - start.x) * amount, y: start.y + (end.y - start.y) * amount)
    }
}

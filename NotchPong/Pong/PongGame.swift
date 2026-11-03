//
//  PongGame.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Observation

/// Runs a match: advances the physics on each frame, moves the computer, and takes the player's paddle input.
@MainActor
@Observable
final class PongGame {
    static let countdownLength = MatchClock.countdownLength

    private(set) var model: PongModel
    private var clock = MatchClock()
    /// Seconds left before the ball moves; runs at the start, after every pause and after every point.
    var countdown: TimeInterval { clock.countdown }
    /// The most recent point, for its explosion and score pop.
    private(set) var lastPoint: PointEvent?
    /// The most recent wall bounce, for its spark.
    private(set) var lastWallHit: WallHit?
    /// The ball's recent positions, oldest first, for its trail.
    private(set) var ballTrail: [(position: CGPoint, time: Date)] = []
    static let trailLength: TimeInterval = 0.08
    var isPaused: Bool {
        get { clock.isPaused }
        set { clock.isPaused = newValue }
    }
    /// Takes effect straight away, even mid-match.
    var difficulty = Difficulty.standard {
        didSet { computer = ComputerOpponent(difficulty: difficulty) }
    }
    var opponentSpeed: CGFloat { computer.maxSpeed }
    private var computer = ComputerOpponent()
    /// Called once when a match is decided, with the side that won.
    @ObservationIgnored var onMatchEnd: ((PongSide) -> Void)?
    /// Where the player last aimed while the paddles were frozen; applied when play starts.
    @ObservationIgnored private var pendingAim: CGFloat?

    /// Paddles only move while the ball is in play: not while paused or counting down.
    var paddlesCanMove: Bool { !isPaused && countdown <= 0 }

    init(model: PongModel = PongModel()) {
        self.model = model
    }

    func reset() {
        model = PongModel()
        computer = ComputerOpponent(difficulty: difficulty)
        clock = MatchClock()
        lastPoint = nil
        lastWallHit = nil
        pendingAim = nil
        ballTrail = []
    }

    func tick(now: Date) {
        let interval: TimeInterval
        switch clock.advance(to: now) {
        case .waiting, .countingDown:
            return
        case .countdownFinished:
            if let pendingAim { setPlayerPaddle(y: pendingAim) }
            pendingAim = nil
            return
        case .playing(let step):
            interval = step
        }
        model.computerY = computer.nextPaddleY(current: model.computerY, ball: model.ball, interval: interval)
        let playerScoreBefore = model.playerScore
        let computerScoreBefore = model.computerScore
        let ballBefore = model.ball.position
        model.step(by: interval)
        ballTrail.append((ballBefore, now))
        ballTrail.removeAll { now.timeIntervalSince($0.time) > Self.trailLength }
        if let bounce = model.wallBounce {
            // Court y runs down, so the top wall (y = 0) sends its spark down.
            let inward = CGVector(dx: 0, dy: bounce.y == 0 ? 1 : -1)
            lastWallHit = WallHit(position: bounce, inward: inward, time: now)
        }
        guard model.playerScore != playerScoreBefore || model.computerScore != computerScoreBefore else { return }
        // The ball is back at the center, so its old trail would streak across the court.
        ballTrail = []
        let side: PongSide = model.playerScore != playerScoreBefore ? .player : .computer
        let exitY = min(max(ballBefore.y, 0), PongModel.courtSize.height)
        lastPoint = PointEvent(
            side: side,
            position: CGPoint(x: side == .computer ? PongModel.courtSize.width : 0, y: exitY),
            time: now
        )
        if let winner = model.winner {
            onMatchEnd?(winner)
        } else {
            clock.startCountdown()
        }
    }

    /// `y` in court units (0 top, 1 bottom); clamped so the paddle stays inside the court.
    func setPlayerPaddle(y height: CGFloat) {
        model.playerY = Self.clampedPaddle(height)
    }

    private static func clampedPaddle(_ height: CGFloat) -> CGFloat {
        let half = PongModel.paddleHeight / 2
        return min(max(height, half), PongModel.courtSize.height - half)
    }

    func nudgePlayerPaddle(by delta: CGFloat) {
        aimPlayerPaddle(y: (pendingAim ?? model.playerY) + delta)
    }

    /// The pointer moved: `courtY` is nil once it's beyond the gutter. Only the panel itself starts a paused game;
    /// the gutter just keeps a running one from pausing when the pointer slips past the edge.
    func pointerMoved(toCourtY courtY: CGFloat?, insidePanel: Bool) {
        guard let courtY else {
            isPaused = true
            return
        }
        if isPaused, !insidePanel { return }
        aimPlayerPaddle(y: courtY)
        if model.winner == nil { isPaused = false }
    }

    /// Player input: moves the paddle during play, or remembers the aim for when play starts.
    func aimPlayerPaddle(y height: CGFloat) {
        if paddlesCanMove {
            setPlayerPaddle(y: height)
        } else {
            pendingAim = height
        }
    }
}

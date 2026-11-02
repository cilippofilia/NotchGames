//
//  PongGame.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Observation

/// Runs a match: advances the physics on each frame, moves the computer (or takes the second player's input),
/// and takes the player's paddle input. With two players the left paddle, `model.computerY`, is the second player's.
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
    var isPaused: Bool {
        get { clock.isPaused }
        set { clock.isPaused = newValue }
    }
    /// Takes effect straight away, even mid-match.
    var difficulty = Difficulty.standard {
        didSet { computer = ComputerOpponent(difficulty: difficulty) }
    }
    var opponentSpeed: CGFloat { computer.maxSpeed }
    /// Takes effect straight away, even mid-match.
    var playerCount = PlayerCount.standard
    private var computer = ComputerOpponent()
    /// Called once when a match is decided, with the side that won.
    @ObservationIgnored var onMatchEnd: ((PongSide) -> Void)?
    /// Where the player last aimed while the paddles were frozen; applied when play starts.
    @ObservationIgnored private var pendingAim: CGFloat?
    @ObservationIgnored private var pendingLeftAim: CGFloat?

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
        pendingLeftAim = nil
    }

    func tick(now: Date) {
        let interval: TimeInterval
        switch clock.advance(to: now) {
        case .waiting, .countingDown:
            return
        case .countdownFinished:
            if let pendingAim { setPlayerPaddle(y: pendingAim) }
            if let pendingLeftAim { model.computerY = Self.clampedPaddle(pendingLeftAim) }
            pendingAim = nil
            pendingLeftAim = nil
            return
        case .playing(let step):
            interval = step
        }
        if playerCount == .one {
            model.computerY = computer.nextPaddleY(current: model.computerY, ball: model.ball, interval: interval)
        }
        let playerScoreBefore = model.playerScore
        let computerScoreBefore = model.computerScore
        let ballBefore = model.ball.position
        model.step(by: interval)
        if let bounce = model.wallBounce { lastWallHit = WallHit(position: bounce, time: now) }
        guard model.playerScore != playerScoreBefore || model.computerScore != computerScoreBefore else { return }
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

    /// Second player's input in two-player mode; ignored when playing the computer.
    func aimLeftPaddle(y height: CGFloat) {
        guard playerCount == .two else { return }
        if paddlesCanMove {
            model.computerY = Self.clampedPaddle(height)
        } else {
            pendingLeftAim = height
        }
    }

    func nudgeLeftPaddle(by delta: CGFloat) {
        aimLeftPaddle(y: (pendingLeftAim ?? model.computerY) + delta)
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

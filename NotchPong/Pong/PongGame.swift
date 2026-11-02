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
    static let countdownLength: TimeInterval = 3

    private(set) var model: PongModel
    /// Seconds left before the ball moves; runs at the start, after every pause and after every point.
    private(set) var countdown: TimeInterval = 0
    /// The most recent point, for its explosion and score pop.
    private(set) var lastPoint: PointEvent?
    var isPaused = true {
        didSet {
            if isPaused {
                lastTick = nil
            } else if oldValue {
                countdown = Self.countdownLength
            }
        }
    }
    /// Takes effect straight away, even mid-match.
    var difficulty = Difficulty.standard {
        didSet { computer = ComputerOpponent(difficulty: difficulty) }
    }
    var opponentSpeed: CGFloat { computer.maxSpeed }
    /// Takes effect straight away, even mid-match.
    var playerCount = PlayerCount.standard
    private var computer = ComputerOpponent()
    @ObservationIgnored private var lastTick: Date?
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
        isPaused = true
        countdown = 0
        lastPoint = nil
        lastTick = nil
        pendingAim = nil
        pendingLeftAim = nil
    }

    func tick(now: Date) {
        guard !isPaused else {
            lastTick = nil
            return
        }
        // The first frame after a pause only starts the clock, so the ball never jumps.
        guard let lastTick else {
            self.lastTick = now
            return
        }
        self.lastTick = now
        let elapsed = now.timeIntervalSince(lastTick)
        let interval = min(elapsed, PongModel.maxStep)
        guard countdown <= 0 else {
            countdown = max(countdown - elapsed, 0)
            if countdown <= 0 {
                if let pendingAim { setPlayerPaddle(y: pendingAim) }
                if let pendingLeftAim { model.computerY = Self.clampedPaddle(pendingLeftAim) }
                pendingAim = nil
                pendingLeftAim = nil
            }
            return
        }
        if playerCount == .one {
            model.computerY = computer.nextPaddleY(current: model.computerY, ball: model.ball, interval: interval)
        }
        let playerScoreBefore = model.playerScore
        let computerScoreBefore = model.computerScore
        let ballBefore = model.ball.position
        model.step(by: interval)
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
            countdown = Self.countdownLength
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

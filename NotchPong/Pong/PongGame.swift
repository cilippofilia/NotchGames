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
    private var computer = ComputerOpponent()
    @ObservationIgnored private var lastTick: Date?

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
        model.computerY = computer.nextPaddleY(current: model.computerY, ball: model.ball, interval: interval)
        guard countdown <= 0 else {
            countdown = max(countdown - elapsed, 0)
            return
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
        if model.winner == nil { countdown = Self.countdownLength }
    }

    /// `y` in court units (0 top, 1 bottom); clamped so the paddle stays inside the court.
    func setPlayerPaddle(y height: CGFloat) {
        let half = PongModel.paddleHeight / 2
        model.playerY = min(max(height, half), PongModel.courtSize.height - half)
    }

    func nudgePlayerPaddle(by delta: CGFloat) {
        setPlayerPaddle(y: model.playerY + delta)
    }
}

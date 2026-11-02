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
    private(set) var model = PongModel()
    var isPaused = true
    private var computer = ComputerOpponent()
    @ObservationIgnored private var lastTick: Date?

    func reset() {
        model = PongModel()
        computer = ComputerOpponent()
        isPaused = true
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
        let interval = min(now.timeIntervalSince(lastTick), PongModel.maxStep)
        model.computerY = computer.nextPaddleY(current: model.computerY, ball: model.ball, interval: interval)
        model.step(by: interval)
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

//
//  ComputerOpponent.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// Moves the left paddle like a player working the shot out: it follows the ball while it's far away,
/// reads the bounce more and more as it gets closer, and fidgets while it waits. It reacts a moment late
/// and has a capped speed, so it can be beaten.
nonisolated struct ComputerOpponent {
    var maxSpeed: CGFloat = Difficulty.standard.opponentSpeed
    var reactionDelay: TimeInterval = Difficulty.standard.reactionDelay
    /// Doesn't twitch for differences smaller than this.
    var deadZone: CGFloat = 0.02

    private var elapsed: TimeInterval = 0
    private static let swayAmount: CGFloat = 0.06
    private static let swaySpeed: Double = 1.8
    /// Extra wobble while it's still unsure where an incoming shot is going.
    private static let doubtWobble: CGFloat = 0.02
    private var sightings: [(time: TimeInterval, height: CGFloat)] = []

    init(maxSpeed: CGFloat = Difficulty.standard.opponentSpeed,
         reactionDelay: TimeInterval = Difficulty.standard.reactionDelay,
         deadZone: CGFloat = 0.02) {
        self.maxSpeed = maxSpeed
        self.reactionDelay = reactionDelay
        self.deadZone = deadZone
    }

    init(difficulty: Difficulty) {
        self.init(maxSpeed: difficulty.opponentSpeed, reactionDelay: difficulty.reactionDelay)
    }

    mutating func nextPaddleY(current: CGFloat, ball: Ball, interval: TimeInterval) -> CGFloat {
        elapsed += interval
        sightings.append((elapsed, guess(for: ball)))
        // React to the newest sighting at least `reactionDelay` old, or the oldest one while none is that old.
        let cutoff = elapsed - reactionDelay
        let seenIndex = sightings.lastIndex { $0.time <= cutoff } ?? 0
        let seenHeight = sightings[seenIndex].height
        sightings.removeFirst(seenIndex)

        // While the ball heads away, sway gently around the middle instead of standing still.
        let idle = PongModel.courtSize.height / 2 + Self.swayAmount * CGFloat(sin(elapsed * Self.swaySpeed))
        let target = ball.velocity.dx < 0 ? seenHeight : idle
        let distance = target - current
        let half = PongModel.paddleHeight / 2
        guard abs(distance) > deadZone else { return min(max(current, half), PongModel.courtSize.height - half) }
        let move = min(max(distance, -maxSpeed * interval), maxSpeed * interval)
        return min(max(current + move, half), PongModel.courtSize.height - half)
    }

    /// Where it thinks an incoming ball will arrive: where the ball is while it's far, where it will really
    /// land (bounces included) as it closes in, with a little wobble while it's still unsure.
    private func guess(for ball: Ball) -> CGFloat {
        let face = PongModel.paddleInset
        let distance = max(ball.position.x - face, 0)
        let certainty = min(max(1 - distance / (PongModel.courtSize.width - face), 0), 1)
        let arrival = PongModel.arrivalY(of: ball, atX: face)
        let wobble = Self.doubtWobble * (1 - certainty) * CGFloat(sin(elapsed * 5))
        return ball.position.y + (arrival - ball.position.y) * certainty + wobble
    }
}

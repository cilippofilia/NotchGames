//
//  ComputerOpponent.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// Moves the left paddle toward where it expected the ball to arrive a moment ago, bounces included,
/// at a capped speed, so it reads angled shots but can still be beaten.
nonisolated struct ComputerOpponent {
    var maxSpeed: CGFloat = 0.55
    var reactionDelay: TimeInterval = 0.2
    /// Doesn't twitch for differences smaller than this.
    var deadZone: CGFloat = 0.02

    private var elapsed: TimeInterval = 0
    private var sightings: [(time: TimeInterval, height: CGFloat)] = []

    mutating func nextPaddleY(current: CGFloat, ball: Ball, interval: TimeInterval) -> CGFloat {
        elapsed += interval
        sightings.append((elapsed, PongModel.arrivalY(of: ball, atX: PongModel.paddleInset)))
        // React to the newest sighting at least `reactionDelay` old, or the oldest one while none is that old.
        let cutoff = elapsed - reactionDelay
        let seenIndex = sightings.lastIndex { $0.time <= cutoff } ?? 0
        let seenHeight = sightings[seenIndex].height
        sightings.removeFirst(seenIndex)

        let target = ball.velocity.dx < 0 ? seenHeight : PongModel.courtSize.height / 2
        let distance = target - current
        let half = PongModel.paddleHeight / 2
        guard abs(distance) > deadZone else { return min(max(current, half), PongModel.courtSize.height - half) }
        let move = min(max(distance, -maxSpeed * interval), maxSpeed * interval)
        return min(max(current + move, half), PongModel.courtSize.height - half)
    }
}

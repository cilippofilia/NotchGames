//
//  Explosion.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// Bursts of pixels: a big one where a point was scored, a small spark where the ball hits a wall.
/// The pieces fan back into the court and fade out.
nonisolated enum Explosion {
    static let duration: TimeInterval = 0.6
    static let sparkDuration: TimeInterval = 0.25

    static func particles(age: TimeInterval, side: PongSide) -> [ExplosionParticle] {
        // The computer scores on the right wall, the player on the left; pieces fly back toward the middle.
        burst(
            age: age,
            duration: duration,
            inward: CGVector(dx: side == .computer ? -1 : 1, dy: 0),
            count: 14,
            reach: 0.25
        )
    }

    /// The top wall is at y = 0 (court y runs down), so its spark flies down; the bottom wall's flies up.
    static func wallSpark(age: TimeInterval, hitTop: Bool) -> [ExplosionParticle] {
        spark(age: age, inward: CGVector(dx: 0, dy: hitTop ? 1 : -1))
    }

    /// A small spark off any wall, flying back into the court along `inward`.
    static func spark(age: TimeInterval, inward: CGVector) -> [ExplosionParticle] {
        burst(age: age, duration: sparkDuration, inward: inward, count: 6, reach: 0.07)
    }

    /// Pieces spread across a fan around `inward`, fast at first, then slowing as they fade.
    /// Big bursts are points and mix pink with teal; small sparks stay teal.
    private static func burst(
        age: TimeInterval,
        duration: TimeInterval,
        inward: CGVector,
        count: Int,
        reach: CGFloat
    ) -> [ExplosionParticle] {
        let alternatesColor = duration == Self.duration
        guard age >= 0, age < duration else { return [] }
        let progress = age / duration
        let travel = reach * CGFloat(1 - pow(1 - progress, 3))
        let heading = atan2(Double(inward.dy), Double(inward.dx))
        return (0..<count).map { index in
            let fraction = (Double(index) + 0.5) / Double(count)
            let angle = heading + (fraction - 0.5) * .pi * 0.9
            // Fixed per piece, so the burst looks scattered but is the same every time.
            let speed = 0.55 + 0.45 * Double((index * 7) % 5) / 4
            return ExplosionParticle(
                offset: CGVector(
                    dx: CGFloat(cos(angle) * speed) * travel,
                    dy: CGFloat(sin(angle) * speed) * travel
                ),
                opacity: 1 - progress,
                isPink: alternatesColor && index.isMultiple(of: 2)
            )
        }
    }
}

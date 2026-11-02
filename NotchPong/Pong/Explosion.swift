//
//  Explosion.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// The burst of pixels where a point was scored. They fan back into the court and fade out.
nonisolated enum Explosion {
    static let duration: TimeInterval = 0.6
    private static let pieceCount = 14
    /// How far the fastest piece travels, in court units.
    private static let reach: CGFloat = 0.25

    static func particles(age: TimeInterval, side: PongSide) -> [ExplosionParticle] {
        guard age >= 0, age < duration else { return [] }
        let progress = age / duration
        // Fast at first, then slowing down.
        let travel = reach * CGFloat(1 - pow(1 - progress, 3))
        // The computer scores on the right wall, the player on the left; pieces fly back toward the middle.
        let inward: CGFloat = side == .computer ? -1 : 1
        return (0..<pieceCount).map { index in
            let fraction = (Double(index) + 0.5) / Double(pieceCount)
            let angle = (fraction - 0.5) * .pi * 0.9
            // Fixed per piece, so the burst looks scattered but is the same every time.
            let speed = 0.55 + 0.45 * Double((index * 7) % 5) / 4
            return ExplosionParticle(
                offset: CGVector(
                    dx: inward * CGFloat(cos(angle) * speed) * travel,
                    dy: CGFloat(sin(angle) * speed) * travel
                ),
                opacity: 1 - progress,
                isPink: index.isMultiple(of: 2)
            )
        }
    }
}

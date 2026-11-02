//
//  ExplosionParticle.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// One pixel of a point explosion, relative to where the ball left the court (court units).
nonisolated struct ExplosionParticle: Equatable {
    let offset: CGVector
    let opacity: Double
    /// Alternates between the ball's pink and the paddles' teal.
    let isPink: Bool
}

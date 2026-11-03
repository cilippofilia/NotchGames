//
//  Spring.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// A damped spring (unit mass) that pulls `value` toward `target`.
struct Spring {
    var value: CGFloat = 0
    var velocity: CGFloat = 0
    var target: CGFloat = 0
    var stiffness: CGFloat
    /// Below 1 overshoots and bounces; 1 or more settles without overshoot.
    var dampingRatio: CGFloat

    /// Small fixed sub-steps keep the integration stable even after a long pause between frames.
    private static let subStep: TimeInterval = 1.0 / 240

    var isSettled: Bool {
        abs(value - target) < 0.5 && abs(velocity) < 5
    }

    mutating func step(by interval: TimeInterval) {
        let damping = 2 * dampingRatio * stiffness.squareRoot()
        var remaining = interval
        while remaining > 0 {
            let delta = CGFloat(min(remaining, Self.subStep))
            let acceleration = -stiffness * (value - target) - damping * velocity
            velocity += acceleration * delta
            value += velocity * delta
            remaining -= Self.subStep
        }
    }
}

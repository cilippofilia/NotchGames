//
//  GalleryBird.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation

/// One bird in the shooting gallery, in court units (1.6 × 1, y down).
nonisolated struct GalleryBird: Equatable {
    enum Phase: Equatable {
        /// Zigzagging around the court, waiting to be shot.
        case flying
        /// Shot: dropping to the ground.
        case falling
        /// Got away: flying straight up and off the top.
        case escaping
    }

    var position: CGPoint
    var velocity: CGVector
    var phase = Phase.flying
    /// Seconds until it changes direction.
    var turnIn: TimeInterval
}

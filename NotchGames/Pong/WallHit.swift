//
//  WallHit.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// The ball or puck just bounced off a wall: where (court units), which way is back into the court, and when,
/// for its spark.
nonisolated struct WallHit: Equatable {
    let position: CGPoint
    let inward: CGVector
    let time: Date
}

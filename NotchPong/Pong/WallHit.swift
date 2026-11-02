//
//  WallHit.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// The ball just bounced off the top or bottom wall: where (court units) and when, for its spark.
nonisolated struct WallHit: Equatable {
    let position: CGPoint
    let time: Date
}

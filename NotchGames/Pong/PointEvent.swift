//
//  PointEvent.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// A point just scored: who won it, where the ball left the court (court units), and when.
nonisolated struct PointEvent: Equatable {
    let side: PongSide
    let position: CGPoint
    let time: Date
}

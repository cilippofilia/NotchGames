//
//  PowerUp.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/13/26.
//

import CoreGraphics

/// A capsule dropped by a broken brick, falling toward the paddle. Caught by the paddle, it takes effect.
nonisolated struct PowerUp: Equatable {
    enum Kind: CaseIterable {
        /// Two yellow extra balls launch from the paddle. Losing them costs nothing.
        case multiBall
        /// The next few bricks hit also break their neighbors.
        case bomb
        /// Every ball slows down for a while.
        case slowdown
    }

    static let size = CGSize(width: 0.05, height: 0.02)
    static let fallSpeed: CGFloat = 0.3

    var kind: Kind
    /// The capsule's center, in court units.
    var position: CGPoint

    var rect: CGRect {
        CGRect(
            x: position.x - Self.size.width / 2,
            y: position.y - Self.size.height / 2,
            width: Self.size.width,
            height: Self.size.height
        )
    }
}

//
//  RunnerObstacle.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics

/// Something in the skater's way, in court units: `minX` is its left edge, `altitude` its bottom above the ground.
nonisolated struct RunnerObstacle: Equatable {
    /// The four ways to clear something, from Skate Run.
    enum Kind: CaseIterable {
        /// Low, jump it with a tap. Comes in rows of up to three once the run is fast.
        case cone
        /// Wide, needs a held (longer) jump.
        case bench
        /// Flies at head height: duck under it.
        case pigeon
        /// Rolls toward the skater, faster than the street.
        case cart

        /// Size in sprite pixels (see `RunnerSprites`).
        var pixels: (columns: Int, rows: Int) {
            switch self {
            case .cone: (5, 6)
            case .bench: (16, 5)
            case .pigeon: (7, 4)
            case .cart: (8, 6)
            }
        }

        var size: CGSize {
            CGSize(
                width: CGFloat(pixels.columns) * RunnerModel.pixel,
                height: CGFloat(pixels.rows) * RunnerModel.pixel
            )
        }

        /// Its bottom above the ground: pigeons fly between a ducking and a standing skater's head.
        var altitude: CGFloat { self == .pigeon ? 0.09 : 0 }
        /// Extra speed toward the skater, on top of the street's.
        var ownSpeed: CGFloat { self == .cart ? 0.3 : 0 }
        /// Score before it starts showing up, so the first seconds are only cones.
        var minScore: Int {
            switch self {
            case .cone: 0
            case .pigeon: 60
            case .bench: 120
            case .cart: 250
            }
        }
        /// How often it's picked among the kinds allowed so far.
        var weight: Double { self == .cone ? 3 : 1 }
    }

    let kind: Kind
    var minX: CGFloat
    /// How many in a row (cones only), `RunnerModel.coneGap` apart.
    let count: Int

    var width: CGFloat {
        CGFloat(count) * kind.size.width + CGFloat(count - 1) * RunnerModel.coneGap
    }

    /// Its box, with y measured up from the ground.
    var box: CGRect {
        CGRect(x: minX, y: kind.altitude, width: width, height: kind.size.height)
    }
}

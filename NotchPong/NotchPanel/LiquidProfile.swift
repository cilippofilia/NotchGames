//
//  LiquidProfile.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// The outline of the black liquid hanging from the notch, from a small drip to the full game panel.
/// Everything is measured below the notch's bottom edge.
nonisolated struct LiquidProfile: Equatable {
    /// How far the panel's neck runs below the notch before the body widens out.
    static let slack: CGFloat = 16
    static let dripHalfWidth: CGFloat = 14
    /// Width of the curve where the drip clings to the notch, like liquid on a surface.
    static let maxFlare: CGFloat = 12
    static let cornerRadius: CGFloat = 16
    /// Hanging length, past a full drip, over which the drip turns into the panel.
    static let morphLength: CGFloat = 200

    var length: CGFloat
    var offsetX: CGFloat
    var attachHalfWidth: CGFloat
    var bodyHalfWidth: CGFloat
    var flare: CGFloat
    /// Depth of the neck before the body reaches its full width.
    var transition: CGFloat
    /// 0 for a drip, 1 for the panel. Drives the neon and the panel's contents.
    var solidity: CGFloat

    /// Window width needed to hold the shape centered on the notch.
    var requiredWidth: CGFloat {
        2 * (abs(offsetX) + max(bodyHalfWidth, attachHalfWidth + flare))
    }

    static func make(length: CGFloat, notchWidth: CGFloat, dropOffset: CGFloat) -> LiquidProfile {
        let progress = min(max((length - Magnet.maxLength) / morphLength, 0), 1)
        let solidity = progress * progress * (3 - 2 * progress)
        let panelHalfWidth = max(max(length - slack, 0) * PullSizing.aspect / 2, dripHalfWidth)
        let bodyHalfWidth = lerp(dripHalfWidth, panelHalfWidth, solidity)
        return LiquidProfile(
            length: length,
            offsetX: lerp(dropOffset, 0, solidity),
            // The neck widens later than the body and never past it, so the shape never pinches.
            attachHalfWidth: min(lerp(dripHalfWidth, notchWidth / 2, solidity * solidity), bodyHalfWidth),
            bodyHalfWidth: bodyHalfWidth,
            flare: lerp(maxFlare, 0, solidity),
            transition: lerp(length / 2, slack, solidity),
            solidity: solidity
        )
    }

    private static func lerp(_ start: CGFloat, _ end: CGFloat, _ amount: CGFloat) -> CGFloat {
        start + (end - start) * amount
    }
}

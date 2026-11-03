//
//  PullSizing.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// What happens when the user lets go of the panel.
nonisolated enum ReleaseOutcome: Equatable {
    case close
    case open(CGSize)
}

/// Maps how far the panel has been pulled to the size of the game area below the menu bar.
nonisolated enum PullSizing {
    static let minBodyHeight: CGFloat = 250
    static let maxBodyHeight: CGFloat = 460
    /// Upward release speed (pt/s) that counts as a flick to close.
    static let flickVelocity: CGFloat = 800
    /// Pulling the drop out of the notch grows the panel this many times faster than the pointer moves.
    static let openingGain: CGFloat = 1.6
    /// How far past the maximum the panel can be stretched while dragging.
    static let maxStretch: CGFloat = 40
    private static let stretchResistance: CGFloat = 0.2

    /// Below the minimum the body is allowed to be smaller, so the panel visibly grows while dragging.
    /// `shape` is the game's (`GameKind.panelShape`).
    static func bodySize(forPull pull: CGFloat, shape: PanelShape) -> CGSize {
        let height = min(max(pull, 0), shape.maxHeight)
        return CGSize(width: height * shape.aspect, height: height)
    }

    /// Height to show while dragging: follows the pull, then gives a little past the maximum like a rubber band.
    static func rubberBandedHeight(forPull pull: CGFloat, maxHeight: CGFloat) -> CGFloat {
        guard pull > maxHeight else { return max(pull, 0) }
        return maxHeight + min((pull - maxHeight) * stretchResistance, maxStretch)
    }

    static func releaseOutcome(pull: CGFloat, upwardVelocity: CGFloat, shape: PanelShape) -> ReleaseOutcome {
        if pull < minBodyHeight || upwardVelocity > flickVelocity { return .close }
        return .open(bodySize(forPull: shape.openHeight(for: pull), shape: shape))
    }
}

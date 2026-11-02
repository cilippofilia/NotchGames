//
//  PullSizing.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// What happens when the user lets go of the panel.
enum ReleaseOutcome: Equatable {
    case close
    case open(CGSize)
}

/// Maps how far the panel has been pulled to the size of the game area below the menu bar.
enum PullSizing {
    static let aspect: CGFloat = 1.6
    static let minBodyHeight: CGFloat = 250
    static let maxBodyHeight: CGFloat = 400
    /// Upward release speed (pt/s) that counts as a flick to close.
    static let flickVelocity: CGFloat = 800
    /// How far past the maximum the panel can be stretched while dragging.
    static let maxStretch: CGFloat = 40
    private static let stretchResistance: CGFloat = 0.2

    /// Below the minimum the body is allowed to be smaller, so the panel visibly grows while dragging.
    static func bodySize(forPull pull: CGFloat) -> CGSize {
        let height = min(max(pull, 0), maxBodyHeight)
        return CGSize(width: height * aspect, height: height)
    }

    /// Height to show while dragging: follows the pull, then gives a little past the maximum like a rubber band.
    static func rubberBandedHeight(forPull pull: CGFloat) -> CGFloat {
        guard pull > maxBodyHeight else { return max(pull, 0) }
        return maxBodyHeight + min((pull - maxBodyHeight) * stretchResistance, maxStretch)
    }

    static func releaseOutcome(pull: CGFloat, upwardVelocity: CGFloat) -> ReleaseOutcome {
        if pull < minBodyHeight || upwardVelocity > flickVelocity { return .close }
        return .open(bodySize(forPull: pull))
    }
}

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

    /// Below the minimum the body is allowed to be smaller, so the panel visibly grows while dragging.
    static func bodySize(forPull pull: CGFloat) -> CGSize {
        let height = min(max(pull, 0), maxBodyHeight)
        return CGSize(width: height * aspect, height: height)
    }

    static func releaseOutcome(pull: CGFloat, upwardVelocity: CGFloat) -> ReleaseOutcome {
        if pull < minBodyHeight || upwardVelocity > flickVelocity { return .close }
        return .open(bodySize(forPull: pull))
    }
}

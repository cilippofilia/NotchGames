//
//  PullTracker.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Turns polled pointer readings into pulls. A pull starts only when the button goes down inside the grab zone,
/// and then follows the pointer until release, wherever it goes.
struct PullTracker {
    private var wasPressed = false
    /// Added to the raw pointer distance so a pull starts at `startPull` instead of jumping.
    private var grabOffset: CGFloat?
    private var previous: PointerSample?
    private var upwardVelocity: CGFloat = 0

    /// `anchorY` is the notch's bottom edge; the raw pull is how far below it the pointer is.
    mutating func handle(
        _ sample: PointerSample,
        grabZone: CGRect?,
        startPull: CGFloat,
        anchorY: CGFloat
    ) -> PointerAction {
        defer { wasPressed = sample.isPressed }
        let rawPull = anchorY - sample.location.y

        if let offset = grabOffset {
            guard sample.isPressed else {
                grabOffset = nil
                previous = nil
                return .release(pull: rawPull + offset, upwardVelocity: upwardVelocity)
            }
            if let previous, sample.time > previous.time {
                upwardVelocity = (sample.location.y - previous.location.y) / (sample.time - previous.time)
            }
            previous = sample
            return .pull(rawPull + offset)
        }

        if sample.isPressed, !wasPressed, let grabZone, grabZone.contains(sample.location) {
            grabOffset = startPull - rawPull
            previous = sample
            upwardVelocity = 0
            return .pull(startPull)
        }
        return .none
    }
}

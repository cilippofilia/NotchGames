//
//  PullTracker.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Turns polled pointer readings into pulls. A pull starts only when the button goes down inside the grab zone,
/// and then follows the pointer until release, wherever it goes.
struct PullTracker {
    private var wasPressed = false
    /// The pointer's raw pull when the current pull started; nil while not pulling.
    private var grabRawPull: CGFloat?
    private var grabStartPull: CGFloat = 0
    private var grabGain: CGFloat = 1
    private var previous: PointerSample?
    private var upwardVelocity: CGFloat = 0

    /// `anchorY` is the notch's bottom edge; the raw pull is how far below it the pointer is.
    /// A pull starts at `startPull` and then moves `gain` times as far as the pointer does.
    mutating func handle(
        _ sample: PointerSample,
        grabZone: CGRect?,
        startPull: CGFloat,
        gain: CGFloat = 1,
        anchorY: CGFloat
    ) -> PointerAction {
        defer { wasPressed = sample.isPressed }
        let rawPull = anchorY - sample.location.y

        if let grabRawPull {
            let pull = grabStartPull + (rawPull - grabRawPull) * grabGain
            guard sample.isPressed else {
                self.grabRawPull = nil
                previous = nil
                return .release(pull: pull, upwardVelocity: upwardVelocity * grabGain)
            }
            if let previous, sample.time > previous.time {
                upwardVelocity = (sample.location.y - previous.location.y) / (sample.time - previous.time)
            }
            previous = sample
            return .pull(pull)
        }

        if sample.isPressed, !wasPressed, let grabZone, grabZone.contains(sample.location) {
            grabRawPull = rawPull
            grabStartPull = startPull
            grabGain = gain
            previous = sample
            upwardVelocity = 0
            return .pull(startPull)
        }
        return .none
    }
}

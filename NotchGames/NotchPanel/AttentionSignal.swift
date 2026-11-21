//
//  AttentionSignal.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// An agent's "come back" ping, sent with `open -g notchgames://attention`. Each one shakes the notch for a few
/// seconds and then stops on its own, so there's nothing to dismiss.
nonisolated enum AttentionSignal {
    static let duration: TimeInterval = 5
    private static let fadeIn: TimeInterval = 0.15
    private static let fadeOut: TimeInterval = 0.5
    private static let bursts = 3
    private static let burstLength: TimeInterval = 0.45
    /// One left-right swing; 0.1 s reads as a buzz rather than a wobble.
    private static let swing: TimeInterval = 0.1
    private static let amplitude: CGFloat = 4

    /// How lit the glow is `time` seconds into a ping, 0...1.
    static func glow(at time: TimeInterval) -> Double {
        guard time > 0, time < duration else { return 0 }
        return min(time / fadeIn, 1, (duration - time) / fadeOut)
    }

    /// Sideways offset in points `time` seconds into a ping: three short buzzes that die down, spread over the ping.
    static func shake(at time: TimeInterval) -> CGFloat {
        guard time >= 0, time < duration else { return 0 }
        let intoBurst = time.truncatingRemainder(dividingBy: duration / Double(bursts))
        guard intoBurst < burstLength else { return 0 }
        let decay = 1 - intoBurst / burstLength
        return amplitude * decay * sin(2 * .pi * intoBurst / swing)
    }

    static func isRequest(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "notchgames" && url.host()?.lowercased() == "attention"
    }
}

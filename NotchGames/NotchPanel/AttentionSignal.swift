//
//  AttentionSignal.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// An agent's "come back" ping, sent with `open -g notchgames://attention`. Each one sends ripples off the notch for
/// a few seconds and then stops on its own, so there's nothing to dismiss.
nonisolated enum AttentionSignal {
    static let duration: TimeInterval = 5
    /// How long one ripple takes to travel out and fade.
    static let rippleLength: TimeInterval = 1.2
    private static let fadeIn: TimeInterval = 0.15
    private static let fadeOut: TimeInterval = 0.5
    private static let bursts = 3
    private static let ripplesPerBurst = 2
    /// Gap between the ripples of one burst, so they read as a wave train rather than one ring.
    private static let rippleStagger: TimeInterval = 0.3
    static let rippleCount = bursts * ripplesPerBurst

    /// How lit the glow is `time` seconds into a ping, 0...1.
    static func glow(at time: TimeInterval) -> Double {
        guard time > 0, time < duration else { return 0 }
        return min(time / fadeIn, 1, (duration - time) / fadeOut)
    }

    /// How far ripple `index` has travelled `time` seconds into a ping, 0..<1, or nil when it isn't out.
    static func rippleProgress(_ index: Int, at time: TimeInterval) -> Double? {
        let burst = index / ripplesPerBurst
        let start = Double(burst) * duration / Double(bursts) + Double(index % ripplesPerBurst) * rippleStagger
        let progress = (time - start) / rippleLength
        return progress >= 0 && progress < 1 ? progress : nil
    }

    static func isRequest(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "notchgames" && url.host()?.lowercased() == "attention"
    }
}

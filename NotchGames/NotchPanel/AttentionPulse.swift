//
//  AttentionPulse.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// Plays once per agent ping for `AttentionSignal.duration`: `ring(0)` glows steadily while ripples, `ring` drawn at
/// their progress 0..<1, travel out and fade. With Reduce Motion on it only glows.
struct AttentionPulse<Ring: View>: View {
    let pings: Int
    @ViewBuilder let ring: (Double) -> Ring
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // One clock runs 0 → duration; the glow and ripples are read off it.
        Color.clear
            .keyframeAnimator(initialValue: 0.0, trigger: pings) { _, time in
                let glow = AttentionSignal.glow(at: time)
                ZStack {
                    ring(0).opacity(glow)
                    if !reduceMotion {
                        ForEach(0..<AttentionSignal.rippleCount, id: \.self) { index in
                            if let progress = AttentionSignal.rippleProgress(index, at: time) {
                                ring(progress).opacity(glow * (1 - progress))
                            }
                        }
                    }
                }
            } keyframes: { _ in
                LinearKeyframe(AttentionSignal.duration, duration: AttentionSignal.duration)
            }
            .allowsHitTesting(false)
    }
}

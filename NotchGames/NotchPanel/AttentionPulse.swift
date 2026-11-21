//
//  AttentionPulse.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// Plays once per agent ping: its content lights up and buzzes for `AttentionSignal.duration`, then goes dark.
/// With Reduce Motion on it glows without shaking.
struct AttentionPulse<Content: View>: View {
    let pings: Int
    @ViewBuilder let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // One clock runs 0 → duration; the glow and shake are read off it.
        content
            .keyframeAnimator(initialValue: 0.0, trigger: pings) { view, time in
                view
                    .opacity(AttentionSignal.glow(at: time))
                    .offset(x: reduceMotion ? 0 : AttentionSignal.shake(at: time))
            } keyframes: { _ in
                LinearKeyframe(AttentionSignal.duration, duration: AttentionSignal.duration)
            }
            .allowsHitTesting(false)
    }
}

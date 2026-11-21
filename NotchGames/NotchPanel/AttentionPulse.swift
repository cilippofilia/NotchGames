//
//  AttentionPulse.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// Breathes its content in and out while an agent wants attention; holds steady with Reduce Motion on.
struct AttentionPulse<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .phaseAnimator([0.25, 1]) { view, opacity in
                view.opacity(reduceMotion ? 1 : opacity)
            } animation: { _ in
                .easeInOut(duration: 0.9)
            }
            .allowsHitTesting(false)
    }
}

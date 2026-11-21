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
    /// When the current ping started; nil while idle, which pauses the timeline.
    @State private var start: Date?

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { context in
            let time = start.map { context.date.timeIntervalSince($0) } ?? -1
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
        }
        .onChange(of: pings) { start = .now }
        .task(id: start) {
            // A newer ping cancels this wait, so only the latest one ends the animation.
            guard start != nil, (try? await Task.sleep(for: .seconds(AttentionSignal.duration))) != nil else { return }
            start = nil
        }
        .allowsHitTesting(false)
    }
}

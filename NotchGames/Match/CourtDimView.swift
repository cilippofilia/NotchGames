//
//  CourtDimView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Darkens the court while nothing is in play (paused, counting down, or over), so the countdown and messages
/// stand out from the bricks and pieces behind them. Sits under the score and messages, which stay bright.
struct CourtDimView: View {
    let isDimmed: Bool

    var body: some View {
        Palette.background
            .opacity(isDimmed ? 0.75 : 0)
            .animation(.easeInOut(duration: 0.25), value: isDimmed)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Palette.ball
        CourtDimView(isDimmed: true)
    }
    .frame(width: 480, height: 300)
}

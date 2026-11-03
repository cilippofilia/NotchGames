//
//  MatchCountdownView.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The 3-2-1 before the ball moves, in the neon dot-matrix font.
struct MatchCountdownView: View {
    let countdown: TimeInterval
    /// Shown only while the game is actually counting down: not paused, not over.
    let isRunning: Bool
    /// Height of the panel; the digit takes about a third of it.
    let panelHeight: CGFloat

    var body: some View {
        if countdown > 0, isRunning {
            let digit = String(Int(countdown.rounded(.up)))
            DotMatrixView(
                rows: PixelArt.embolden(PixelFont.rows(for: digit)),
                colors: ["#": Palette.ball]
            )
            .frame(height: panelHeight * 0.3)
            .accessibilityLabel(digit)
        }
    }
}

#Preview {
    MatchCountdownView(countdown: 2.4, isRunning: true, panelHeight: 300)
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

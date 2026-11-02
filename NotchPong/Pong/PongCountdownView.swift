//
//  PongCountdownView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The 3-2-1 before the ball moves, in the neon dot-matrix font.
struct PongCountdownView: View {
    let game: PongGame
    /// Height of the panel; the digit takes about a third of it.
    let panelHeight: CGFloat

    var body: some View {
        if game.countdown > 0, !game.isPaused, game.model.winner == nil {
            let digit = String(Int(game.countdown.rounded(.up)))
            DotMatrixView(
                rows: PixelArt.embolden(PixelFont.rows(for: digit)),
                colors: ["#": Palette.ball]
            )
            .frame(height: panelHeight * 0.3)
            .accessibilityLabel(digit)
        }
    }
}

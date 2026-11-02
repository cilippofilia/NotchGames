//
//  PongMessageView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// "Move here to play" while paused, or the result with a way to play again.
struct PongMessageView: View {
    let game: PongGame

    var body: some View {
        // Two-thirds down the court, clear of the serve in the middle.
        VStack {
            Spacer()
            Spacer()
            if let winner = game.model.winner {
                Text(winner == .player ? "You win" : "Computer wins")
                    .font(.system(.title, design: .monospaced))
                    .bold()
                    .foregroundStyle(winner == .player ? Palette.paddle : Palette.ball)
                Button("Play again") {
                    game.reset()
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.paddle.opacity(0.4))
            } else if game.isPaused {
                Text("Move here to play")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

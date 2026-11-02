//
//  PongMessageView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// "move here to play" while paused, or the result with a way to play again. All lowercase, the game's style.
struct PongMessageView: View {
    let game: PongGame

    var body: some View {
        // Two-thirds down the court, clear of the serve in the middle.
        VStack {
            Spacer()
            Spacer()
            if let winner = game.model.winner {
                Text(Self.resultText(winner: winner, players: game.playerCount))
                    .font(.system(.title, design: .monospaced))
                    .bold()
                    .foregroundStyle(winner == .player ? Palette.paddle : Palette.ball)
                if game.playerCount == .one {
                    Text("streak \(StatsStore.shared.stats.currentStreak)")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Button("play again") {
                    game.reset()
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.paddle.opacity(0.4))
            } else if game.isPaused {
                Text("move here to play")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private static func resultText(winner: PongSide, players: PlayerCount) -> String {
        switch (players, winner) {
        case (.one, .player): String(localized: "you win")
        case (.one, .computer): String(localized: "computer wins")
        case (.two, .player): String(localized: "right wins")
        case (.two, .computer): String(localized: "left wins")
        }
    }
}

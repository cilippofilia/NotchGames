//
//  MatchMessageView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// "move here to play" while paused, restart and settings while waiting, or the result with a way to play again.
/// All lowercase, the game's style.
struct MatchMessageView: View {
    let winner: PongSide?
    let isPaused: Bool
    let isCountingDown: Bool
    let onRestart: () -> Void

    var body: some View {
        // Two-thirds down the court, clear of the serve in the middle.
        VStack {
            Spacer()
            Spacer()
            if let winner {
                Text(winner == .player ? "you win" : "computer wins")
                    .font(.system(.title, design: .monospaced))
                    .bold()
                    .foregroundStyle(winner == .player ? Palette.paddle : Palette.ball)
                Text("streak \(StatsStore.shared.stats.currentStreak)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button("play again", action: onRestart)
                .buttonStyle(.borderedProminent)
                .tint(Palette.paddle.opacity(0.4))
            } else if isPaused || isCountingDown {
                if isPaused {
                    Text("move here to play")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                MatchControlsView(onRestart: onRestart)
            }
            Spacer()
        }
    }
}

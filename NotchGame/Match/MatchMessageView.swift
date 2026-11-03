//
//  MatchMessageView.swift
//  NotchGame
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
    /// The game can't resume until Settings closes, so the hint says so.
    let isSettingsOpen: Bool
    /// Set when a score-based run has ended; shown instead of a winner.
    var runResult: RunResult?
    let onRestart: () -> Void

    var body: some View {
        VStack {
            if let runResult {
                Text("game over")
                    .font(.system(.title, design: .monospaced))
                    .bold()
                    .foregroundStyle(Palette.ball)
                Text("score \(runResult.score)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(Palette.paddle)
                Text(runResult.isNewBest ? "new best" : "best \(runResult.best)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button("play again", action: onRestart)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .padding()
            } else if let winner {
                Text(winner == .player ? "you win" : "computer wins")
                    .font(.system(.title, design: .monospaced))
                    .bold()
                    .foregroundStyle(winner == .player ? Palette.paddle : Palette.ball)
                if StatsStore.shared.stats.currentStreak > 0 {
                    Text("streak \(StatsStore.shared.stats.currentStreak)")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Button("play again", action: onRestart)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .padding()
            } else if isPaused || isCountingDown {
                if isPaused {
                    if isSettingsOpen {
                        Text("close settings and")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Text("move here to play")
                        .font(.system(.title, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                MatchControlsView(onRestart: onRestart)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview("Paused") {
    MatchMessageView(winner: nil, isPaused: true, isCountingDown: false, isSettingsOpen: true, onRestart: {})
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

#Preview("Won") {
    MatchMessageView(winner: .player, isPaused: false, isCountingDown: false, isSettingsOpen: false, onRestart: {})
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

#Preview("Game over") {
    MatchMessageView(
        winner: nil,
        isPaused: false,
        isCountingDown: false,
        isSettingsOpen: false,
        runResult: RunResult(score: 1240, best: 1240, isNewBest: true),
        onRestart: {}
    )
    .frame(width: 368, height: 460)
    .background(Palette.background)
}

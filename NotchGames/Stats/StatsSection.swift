//
//  StatsSection.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// One game's record in Settings: wins, losses and streaks against the computer, or the best score.
/// The reset clears only this game.
struct StatsSection: View {
    let store: StatsStore
    let game: GameKind

    var body: some View {
        Section("record") {
            if game.hasOpponent {
                let record = store.stats.matchRecord(for: game)
                LabeledContent("wins", value: record.wins, format: .number)
                LabeledContent("losses", value: record.losses, format: .number)
                LabeledContent("current streak", value: record.currentStreak, format: .number)
                LabeledContent("best streak", value: record.bestStreak, format: .number)
            } else {
                LabeledContent("best score", value: store.stats.bestScore(for: game), format: .number)
            }
            Button("reset \(game.title) record", role: .destructive) {
                store.reset(game)
            }
        }
        .contentTransition(.numericText())
        .animation(.snappy, value: store.stats)
    }
}

#Preview {
    Form {
        StatsSection(store: StatsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard), game: .pong)
    }
    .formStyle(.grouped)
}

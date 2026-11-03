//
//  StatsSection.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The player's record in Settings, with a way to start over.
struct StatsSection: View {
    let store: StatsStore

    var body: some View {
        Section("record") {
            LabeledContent("wins", value: store.stats.wins, format: .number)
            LabeledContent("losses", value: store.stats.losses, format: .number)
            LabeledContent("current streak", value: store.stats.currentStreak, format: .number)
            LabeledContent("best streak", value: store.stats.bestStreak, format: .number)
            LabeledContent("brick breaker best", value: store.stats.bestScore(for: .brickBreaker), format: .number)
            Button("reset record", role: .destructive) {
                store.reset()
            }
        }
        .contentTransition(.numericText())
        .animation(.snappy, value: store.stats)
    }
}

#Preview {
    Form {
        StatsSection(store: StatsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard))
    }
    .formStyle(.grouped)
}

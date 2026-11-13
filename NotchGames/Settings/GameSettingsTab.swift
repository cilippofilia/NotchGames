//
//  GameSettingsTab.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// One game's Settings tab: its own options (difficulty, Snake's walls) and its record, with a reset for just
/// this game.
struct GameSettingsTab: View {
    let game: GameKind

    @AppStorage private var difficulty: Difficulty
    @AppStorage(SnakeGame.wallsStorageKey) private var snakeHasWalls = true

    init(game: GameKind) {
        self.game = game
        _difficulty = AppStorage(wrappedValue: Difficulty.standard, Difficulty.storageKey(for: game))
    }

    var body: some View {
        Form {
            if game.hasOpponent {
                Picker(selection: $difficulty) {
                    ForEach(Difficulty.allCases) { level in
                        Text(level.title).tag(level)
                    }
                } label: {
                    Text("difficulty")
                    Text("how fast and sharp the computer plays")
                }
                .pickerStyle(.segmented)
            }

            if game == .snake {
                Toggle(isOn: $snakeHasWalls) {
                    Text("walls")
                }
            }

            StatsSection(store: StatsStore.shared, game: game)
        }
        .settingsTabLayout()
    }
}

#Preview {
    GameSettingsTab(game: .pong)
}

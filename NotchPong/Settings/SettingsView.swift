//
//  SettingsView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The app's Settings window: which game to play and how hard the computer plays.
struct SettingsView: View {
    @AppStorage(GameKind.storageKey) private var game = GameKind.standard
    @AppStorage(Difficulty.storageKey) private var difficulty = Difficulty.standard

    var body: some View {
        Form {
            Picker("game", selection: $game) {
                ForEach(GameKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)

            Picker("difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text("how fast the computer moves and how quickly it reacts. changes apply right away.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(minWidth: 360)
        .fixedSize()
    }
}

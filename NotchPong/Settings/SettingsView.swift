//
//  SettingsView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The app's Settings window: how hard the computer plays.
/// The game picker comes back once there's more than one game (`GameKind`).
struct SettingsView: View {
    @AppStorage(Difficulty.storageKey) private var difficulty = Difficulty.standard

    var body: some View {
        Form {
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

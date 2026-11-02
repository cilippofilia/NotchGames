//
//  SettingsView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The app's Settings window: for now, how hard the computer plays.
struct SettingsView: View {
    @AppStorage(Difficulty.storageKey) private var difficulty = Difficulty.standard

    var body: some View {
        Form {
            Picker("Difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.radioGroup)

            Text("How fast the computer moves and how quickly it reacts. Changes apply right away.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(minWidth: 360)
        .fixedSize()
    }
}

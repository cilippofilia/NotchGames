//
//  SettingsView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The app's Settings window: how hard the computer plays and how forgiving the pause edge is.
/// The game picker comes back once there's more than one game (`GameKind`).
struct SettingsView: View {
    @AppStorage(Difficulty.storageKey) private var difficulty = Difficulty.standard
    @AppStorage(GutterSize.storageKey) private var gutter = GutterSize.standard

    var body: some View {
        Form {
            // A second text in the label shows as a grey subtitle under the setting's name, in the same row.
            Picker(selection: $difficulty) {
                ForEach(Difficulty.allCases) { level in
                    Text(level.title).tag(level)
                }
            } label: {
                Text("difficulty")
                Text("how fast and sharp the computer plays")
            }
            .pickerStyle(.segmented)

            Picker(selection: $gutter) {
                ForEach(GutterSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            } label: {
                Text("gutter")
                Text("how far you can stray before the game pauses")
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize()
    }
}

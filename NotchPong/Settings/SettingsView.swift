//
//  SettingsView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The app's Settings window: the game, players and difficulty, the panel, and the player's record.
struct SettingsView: View {
    @AppStorage(GameKind.storageKey) private var game = GameKind.standard
    @AppStorage(Difficulty.storageKey) private var difficulty = Difficulty.standard
    @AppStorage(GutterSize.storageKey) private var gutter = GutterSize.standard
    @AppStorage(PanelSize.storageKey) private var panelSize = PanelSize.standard
    @AppStorage(PlayerCount.storageKey) private var players = PlayerCount.standard
    @State private var launchesAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Picker("game", selection: $game) {
                ForEach(GameKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)

            Picker(selection: $players) {
                ForEach(PlayerCount.allCases) { count in
                    Text(count.title).tag(count)
                }
            } label: {
                Text("players")
                Text("2 players: left on W/S (W/A/S/D in air hockey), right on the pointer or arrows")
            }
            .pickerStyle(.segmented)

            Picker(selection: $difficulty) {
                ForEach(Difficulty.allCases) { level in
                    Text(level.title).tag(level)
                }

            StatsSection(store: StatsStore.shared)
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

            Picker(selection: $panelSize) {
                ForEach(PanelSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            } label: {
                Text("panel size")
                Text("how big \"play\" opens the game")
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $launchesAtLogin) {
                Text("launch at login")
                Text("keep the drop ready under the notch")
            }
            .onChange(of: launchesAtLogin) { _, enabled in
                LoginItem.setEnabled(enabled)
                // Show what macOS actually did, in case it refused.
                launchesAtLogin = LoginItem.isEnabled
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize()
    }
}

#Preview {
    SettingsView()
}

//
//  SettingsView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The app's Settings window: the game and difficulty, the panel, and the player's record.
struct SettingsView: View {
    @AppStorage(GameKind.storageKey) private var game = GameKind.standard
    @AppStorage(Difficulty.storageKey) private var difficulty = Difficulty.standard
    @AppStorage(GutterSize.storageKey) private var gutter = GutterSize.standard
    @AppStorage(PanelSize.storageKey) private var panelSize = PanelSize.standard
    @AppStorage(SnakeGame.wallsStorageKey) private var snakeHasWalls = true
    @State private var launchesAtLogin = LoginItem.isEnabled
    @Environment(PanelState.self) private var panelState

    var body: some View {
        Form {
            Picker("game", selection: $game) {
                ForEach(GameKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)

            Picker(selection: $difficulty) {
                ForEach(Difficulty.allCases) { level in
                    Text(level.title).tag(level)
                }
            } label: {
                Text("difficulty")
                Text("how fast and sharp the computer plays")
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $snakeHasWalls) {
                Text("snake walls")
                Text("on, hitting the edge ends the run; off, the snake comes out the other side")
            }

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

            StatsSection(store: StatsStore.shared)
        }
        .formStyle(.grouped)
        // Width can be dragged within these bounds; height always fits the content.
        .frame(minWidth: 420, idealWidth: 480, maxWidth: 720)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { panelState.isSettingsOpen = true }
        .onDisappear { panelState.isSettingsOpen = false }
    }
}

#Preview {
    SettingsView()
        .environment(PanelState())
}

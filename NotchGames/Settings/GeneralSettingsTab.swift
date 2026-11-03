//
//  GeneralSettingsTab.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Settings for the panel and the app: which game opens, how big, how forgiving the pointer is, and login.
struct GeneralSettingsTab: View {
    @AppStorage(GameKind.storageKey) private var game = GameKind.standard
    @AppStorage(PanelSize.storageKey) private var panelSize = PanelSize.standard
    @AppStorage(GutterSize.storageKey) private var gutter = GutterSize.standard
    @State private var launchesAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Picker("game", selection: $game) {
                ForEach(GameKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.menu)

            Picker(selection: $panelSize) {
                ForEach(PanelSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            } label: {
                Text("panel size")
                Text("how big \"play\" opens the game; brick breaker always opens full size")
            }
            .pickerStyle(.segmented)

            Picker(selection: $gutter) {
                ForEach(GutterSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            } label: {
                Text("gutter")
                Text("how far the pointer can stray before pong, air hockey or brick breaker pause")
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
        .settingsTabLayout()
    }
}

#Preview {
    GeneralSettingsTab()
}

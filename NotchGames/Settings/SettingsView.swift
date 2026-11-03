//
//  SettingsView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The app's Settings window: a General tab for the panel and the app, then a tab per game with its own options
/// and record.
struct SettingsView: View {
    @Environment(PanelState.self) private var panelState

    var body: some View {
        TabView {
            Tab("general", systemImage: "gearshape") {
                GeneralSettingsTab()
            }
            ForEach(GameKind.allCases) { game in
                Tab(game.title, systemImage: game.symbolName) {
                    GameSettingsTab(game: game)
                }
            }
        }
        // On the window, not a tab: tabs disappear as you switch, which would briefly look like Settings closed
        // and hand the keyboard back to the panel.
        .onAppear { panelState.isSettingsOpen = true }
        .onDisappear { panelState.isSettingsOpen = false }
    }
}

#Preview {
    SettingsView()
        .environment(PanelState())
}

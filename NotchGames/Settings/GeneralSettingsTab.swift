//
//  GeneralSettingsTab.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Settings for the panel and the app: which game opens, how big, how forgiving the pointer is, login, and agent pings.
struct GeneralSettingsTab: View {
    @AppStorage(GameKind.storageKey) private var game = GameKind.standard
    @AppStorage(PanelSize.storageKey) private var panelSize = PanelSize.standard
    @AppStorage(GutterSize.storageKey) private var gutter = GutterSize.standard
    @AppStorage(SideColor.playerStorageKey) private var playerColor = SideColor.playerStandard
    @AppStorage(SideColor.computerStorageKey) private var computerColor = SideColor.computerStandard
    @State private var launchesAtLogin = LoginItem.isEnabled
    @AppStorage(AgentConnection.enabledKey) private var agentPings = true
    private let connection = AgentConnection.shared

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

            Section("colors") {
                SideColorPicker(title: "you", selection: $playerColor, other: $computerColor)
                SideColorPicker(title: "computer", selection: $computerColor, other: $playerColor)
            }

            Toggle(isOn: $launchesAtLogin) {
                Text("launch at login")
                Text("keep the drop ready under the notch")
            }
            .onChange(of: launchesAtLogin) { _, enabled in
                LoginItem.setEnabled(enabled)
                // Show what macOS actually did, in case it refused.
                launchesAtLogin = LoginItem.isEnabled
            }

            Section("agent pings") {
                AgentRow(connection: connection)
                ForEach(connection.available) { agent in
                    Toggle(agent.title, isOn: Binding(
                        get: { connection.connected.contains(agent) },
                        set: { connection.setConnected(agent, $0) }
                    ))
                }
                if connection.isConnected {
                    Toggle(isOn: $agentPings) {
                        Text("pings")
                        Text("light up the notch when an agent needs you or finishes")
                    }
                }
                PingCommandRow()
            }
        }
        .onAppear(perform: connection.refresh)
        .settingsTabLayout()
    }
}

#Preview {
    GeneralSettingsTab()
}

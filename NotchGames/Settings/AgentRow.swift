//
//  AgentRow.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// The agent link in Settings: connect finds the installed agents, delete removes the ping from all of them.
struct AgentRow: View {
    let connection: AgentConnection

    var body: some View {
        LabeledContent {
            if !connection.available.isEmpty {
                Button("delete", systemImage: "trash", role: .destructive, action: connection.disconnect)
                    .foregroundStyle(.red)
            } else {
                Button("connect", action: connection.connect)
            }
        } label: {
            Text("coding agents")
            if connection.isConnected {
                Text("connected: \(connection.connected.map(\.title).formatted(.list(type: .and)))")
            } else if !connection.available.isEmpty {
                Text("switch on the agents that should ping")
            } else {
                Text("finds claude code, codex or cursor and pings when they need you or finish")
            }
            if let problem = connection.problem {
                Text(problem).foregroundStyle(.red)
            }
        }
    }
}

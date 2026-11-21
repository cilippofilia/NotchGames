//
//  AgentRow.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// One agent in Settings: connect it, or delete its ping once connected.
struct AgentRow: View {
    let agent: Agent
    let connection: AgentConnection

    var body: some View {
        LabeledContent {
            if connection.connected.contains(agent) {
                Button("delete", systemImage: "trash", role: .destructive) { connection.disconnect(agent) }
                    .foregroundStyle(.red)
            } else {
                Button("connect") { connection.connect(agent) }
            }
        } label: {
            Text(agent.title)
            if let problem = connection.problems[agent] {
                Text(problem).foregroundStyle(.red)
            } else {
                Text(connection.connected.contains(agent) ? "connected" : "not connected")
            }
        }
    }
}

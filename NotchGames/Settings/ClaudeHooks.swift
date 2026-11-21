//
//  ClaudeHooks.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// Adds and removes the agent-ping hooks in Claude Code's `settings.json`, leaving every other setting and hook alone.
nonisolated enum ClaudeHooks {
    static let command = JSONSettings.pingCommand
    /// Input needed, and reply finished.
    private static let events = ["Notification", "Stop"]

    static func isInstalled(in settings: Data?) throws -> Bool {
        let hooks = try JSONSettings.object(settings)["hooks"] as? [String: Any] ?? [:]
        return events.allSatisfy { event in
            (hooks[event] as? [Any] ?? []).contains(where: isOurs)
        }
    }

    static func installing(into settings: Data?) throws -> Data {
        var root = try JSONSettings.object(settings)
        var hooks = root["hooks"] as? [String: Any] ?? [:]
        for event in events {
            var groups = hooks[event] as? [Any] ?? []
            if !groups.contains(where: isOurs) {
                groups.append(["hooks": [["type": "command", "command": command]]])
            }
            hooks[event] = groups
        }
        root["hooks"] = hooks
        return try JSONSettings.encode(root)
    }

    static func removing(from settings: Data) throws -> Data {
        var root = try JSONSettings.object(settings)
        guard var hooks = root["hooks"] as? [String: Any] else { return settings }
        for event in events {
            let groups = (hooks[event] as? [Any] ?? []).filter { !isOurs($0) }
            hooks[event] = groups.isEmpty ? nil : groups
        }
        root["hooks"] = hooks.isEmpty ? nil : hooks
        return try JSONSettings.encode(root)
    }

    /// A matcher group is ours when one of its commands is the ping.
    private static func isOurs(_ group: Any) -> Bool {
        ((group as? [String: Any])?["hooks"] as? [Any] ?? []).contains(where: JSONSettings.isPing)
    }
}

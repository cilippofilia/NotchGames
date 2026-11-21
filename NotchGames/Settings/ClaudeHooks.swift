//
//  ClaudeHooks.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// Adds and removes the agent-ping hooks in Claude Code's `settings.json`, leaving every other setting and hook alone.
nonisolated enum ClaudeHooks {
    /// What the hook runs; `|| true` keeps Claude Code quiet when the app isn't installed.
    static let command = "open -g notchgames://attention 2>/dev/null || true"
    /// Input needed, and reply finished.
    private static let events = ["Notification", "Stop"]

    enum Failure: Error {
        /// The file isn't a JSON object, so rewriting it could lose the user's settings.
        case notASettingsObject
    }

    static func isInstalled(in settings: Data?) throws -> Bool {
        let hooks = try object(settings)["hooks"] as? [String: Any] ?? [:]
        return events.allSatisfy { event in
            (hooks[event] as? [Any] ?? []).contains(where: isOurs)
        }
    }

    static func installing(into settings: Data?) throws -> Data {
        var root = try object(settings)
        var hooks = root["hooks"] as? [String: Any] ?? [:]
        for event in events {
            var groups = hooks[event] as? [Any] ?? []
            if !groups.contains(where: isOurs) {
                groups.append(["hooks": [["type": "command", "command": command]]])
            }
            hooks[event] = groups
        }
        root["hooks"] = hooks
        return try encode(root)
    }

    static func removing(from settings: Data) throws -> Data {
        var root = try object(settings)
        guard var hooks = root["hooks"] as? [String: Any] else { return settings }
        for event in events {
            let groups = (hooks[event] as? [Any] ?? []).filter { !isOurs($0) }
            hooks[event] = groups.isEmpty ? nil : groups
        }
        root["hooks"] = hooks.isEmpty ? nil : hooks
        return try encode(root)
    }

    /// A matcher group is ours when one of its commands opens the attention URL, including hand-written ones.
    private static func isOurs(_ group: Any) -> Bool {
        let commands = (group as? [String: Any])?["hooks"] as? [[String: Any]] ?? []
        return commands.contains { ($0["command"] as? String)?.contains("notchgames://attention") == true }
    }

    private static func object(_ settings: Data?) throws -> [String: Any] {
        guard let settings, !settings.isEmpty else { return [:] }
        guard let root = try? JSONSerialization.jsonObject(with: settings) as? [String: Any] else {
            throw Failure.notASettingsObject
        }
        return root
    }

    private static func encode(_ root: [String: Any]) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
    }
}

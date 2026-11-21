//
//  CursorHooks.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// Adds and removes the ping in Cursor's `hooks.json`, run when the agent stops.
nonisolated enum CursorHooks {
    private static let event = "stop"

    static func isInstalled(in hooksFile: Data?) throws -> Bool {
        let hooks = try JSONSettings.object(hooksFile)["hooks"] as? [String: Any] ?? [:]
        return (hooks[event] as? [Any] ?? []).contains(where: JSONSettings.isPing)
    }

    static func installing(into hooksFile: Data?) throws -> Data {
        var root = try JSONSettings.object(hooksFile)
        var hooks = root["hooks"] as? [String: Any] ?? [:]
        var entries = hooks[event] as? [Any] ?? []
        if !entries.contains(where: JSONSettings.isPing) {
            entries.append(["command": JSONSettings.pingCommand])
        }
        hooks[event] = entries
        root["hooks"] = hooks
        root["version"] = root["version"] ?? 1
        return try JSONSettings.encode(root)
    }

    static func removing(from hooksFile: Data) throws -> Data {
        var root = try JSONSettings.object(hooksFile)
        guard var hooks = root["hooks"] as? [String: Any] else { return hooksFile }
        let entries = (hooks[event] as? [Any] ?? []).filter { !JSONSettings.isPing($0) }
        hooks[event] = entries.isEmpty ? nil : entries
        root["hooks"] = hooks
        return try JSONSettings.encode(root)
    }
}

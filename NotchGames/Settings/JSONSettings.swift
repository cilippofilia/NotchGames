//
//  JSONSettings.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// Reading and writing an agent's JSON config as a plain dictionary, so keys the app doesn't know survive.
nonisolated enum JSONSettings {
    /// The ping every hook runs; `|| true` keeps the agent quiet when NotchGames isn't installed.
    static let pingCommand = "open -g notchgames://attention 2>/dev/null || true"

    /// A missing or empty file reads as `{}`; anything that isn't an object throws.
    static func object(_ data: Data?) throws -> [String: Any] {
        guard let data, !data.isEmpty else { return [:] }
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AgentConfigError.notASettingsObject
        }
        return root
    }

    static func encode(_ root: [String: Any]) throws -> Data {
        try JSONSerialization.data(
            withJSONObject: root, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
    }

    /// Any command opening the attention URL counts as ours, including hand-written ones.
    static func isPing(_ entry: Any) -> Bool {
        ((entry as? [String: Any])?["command"] as? String)?.contains("notchgames://attention") == true
    }
}

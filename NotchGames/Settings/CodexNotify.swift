//
//  CodexNotify.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// Adds and removes the ping as Codex's top-level `notify` command in `config.toml`, run after each turn.
/// Edits whole lines rather than parsing TOML, so the rest of the file stays byte for byte.
nonisolated enum CodexNotify {
    /// Codex appends a JSON argument; `sh -c` drops it (it lands in `$1`) so `open` only sees the URL.
    static let line = #"notify = ["sh", "-c", "open -g notchgames://attention 2>/dev/null || true", "notchgames"]"#

    static func isInstalled(in config: Data?) throws -> Bool {
        topLevelLines(of: try lines(config)).contains(where: isOurs)
    }

    static func installing(into config: Data?) throws -> Data {
        let existing = try lines(config)
        let topLevel = topLevelLines(of: existing)
        if topLevel.contains(where: isOurs) { return config ?? Data() }
        guard !topLevel.contains(where: isNotify) else { throw AgentConfigError.notifySlotTaken }
        // Above the first table header is always top level.
        let text = ([line] + existing).joined(separator: "\n")
        return Data((existing.isEmpty ? text + "\n" : text).utf8)
    }

    static func removing(from config: Data) throws -> Data {
        let text = try lines(config).filter { !isOurs($0) }.joined(separator: "\n")
        return Data(text.utf8)
    }

    private static func lines(_ config: Data?) throws -> [String] {
        guard let config, !config.isEmpty else { return [] }
        // Not UTF-8 means not TOML: refuse rather than rewrite it.
        guard let text = String(bytes: config, encoding: .utf8) else { throw AgentConfigError.unreadable }
        return text.components(separatedBy: "\n")
    }

    /// Keys before the first `[table]` header belong to the root table, which is where `notify` lives.
    private static func topLevelLines(of lines: [String]) -> ArraySlice<String> {
        lines.prefix { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("[") }
    }

    private static func isNotify(_ line: String) -> Bool {
        let key = line.trimmingCharacters(in: .whitespaces)
        return key.hasPrefix("notify ") || key.hasPrefix("notify=")
    }

    private static func isOurs(_ line: String) -> Bool {
        isNotify(line) && line.contains("notchgames://attention")
    }
}

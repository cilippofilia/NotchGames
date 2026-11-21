//
//  Agent.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// A coding agent NotchGames can hook into, and where its config lives under the home folder.
nonisolated enum Agent: String, CaseIterable, Identifiable {
    case claude, codex, cursor

    var id: Self { self }

    var title: String {
        switch self {
        case .claude: String(localized: "claude code")
        case .codex: String(localized: "codex")
        case .cursor: String(localized: "cursor")
        }
    }

    /// The folder the user grants, e.g. `.claude`.
    var folderName: String { "." + rawValue }

    var fileName: String {
        switch self {
        case .claude: "settings.json"
        case .codex: "config.toml"
        case .cursor: "hooks.json"
        }
    }

    func isInstalled(in config: Data?) throws -> Bool {
        switch self {
        case .claude: try ClaudeHooks.isInstalled(in: config)
        case .codex: try CodexNotify.isInstalled(in: config)
        case .cursor: try CursorHooks.isInstalled(in: config)
        }
    }

    func installing(into config: Data?) throws -> Data {
        switch self {
        case .claude: try ClaudeHooks.installing(into: config)
        case .codex: try CodexNotify.installing(into: config)
        case .cursor: try CursorHooks.installing(into: config)
        }
    }

    func removing(from config: Data) throws -> Data {
        switch self {
        case .claude: try ClaudeHooks.removing(from: config)
        case .codex: try CodexNotify.removing(from: config)
        case .cursor: try CursorHooks.removing(from: config)
        }
    }
}

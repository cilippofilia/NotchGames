//
//  AgentConnection.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import AppKit
import Observation

/// The links to coding agents. The sandbox only lets the app into an agent's folder (e.g. `~/.claude`) after the
/// user picks it once, so each grant is kept as a bookmark and the ping is added and removed through it.
@MainActor @Observable
final class AgentConnection {
    static let shared = AgentConnection()
    /// Pings can be muted without removing any hooks.
    static let enabledKey = "agentPingsEnabled"

    static var pingsEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    private(set) var connected: Set<Agent> = []
    private(set) var problems: [Agent: String] = [:]

    /// Connected means the ping is in the file now, so hand edits show up here.
    func refresh() {
        connected = Set(Agent.allCases.filter { agent in
            (try? withFolder(of: agent) { file in try agent.isInstalled(in: try? Data(contentsOf: file)) }) == true
        })
    }

    func connect(_ agent: Agent) {
        problems[agent] = nil
        do {
            if UserDefaults.standard.data(forKey: Self.bookmarkKey(agent)) == nil {
                guard try askForFolder(of: agent) else { return }
            }
            try withFolder(of: agent) { file in
                try agent.installing(into: try? Data(contentsOf: file)).write(to: file, options: .atomic)
            }
        } catch {
            problems[agent] = Self.message(for: error, agent: agent)
        }
        refresh()
    }

    func disconnect(_ agent: Agent) {
        problems[agent] = nil
        do {
            try withFolder(of: agent) { file in
                // No file means no ping: nothing to remove.
                guard let config = try? Data(contentsOf: file) else { return }
                try agent.removing(from: config).write(to: file, options: .atomic)
            }
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey(agent))
        } catch {
            problems[agent] = Self.message(for: error, agent: agent)
        }
        refresh()
    }

    /// Returns false when the user cancels or picks the wrong folder.
    private func askForFolder(of agent: Agent) throws -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.showsHiddenFiles = true
        panel.directoryURL = Self.home?.appending(path: agent.folderName)
        panel.prompt = String(localized: "allow")
        panel.message = String(
            localized: "allow NotchGames to add its ping to \(agent.title)'s settings in this folder"
        )
        guard panel.runModal() == .OK, let folder = panel.url else { return false }
        guard folder.lastPathComponent == agent.folderName else {
            problems[agent] = String(localized: "choose the \(agent.folderName) folder in your home folder")
            return false
        }
        let bookmark = try folder.bookmarkData(options: .withSecurityScope)
        UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey(agent))
        return true
    }

    /// Runs `body` with access to the agent's config file; nil when there's no grant yet.
    @discardableResult
    private func withFolder<T>(of agent: Agent, _ body: (URL) throws -> T) throws -> T? {
        let key = Self.bookmarkKey(agent)
        guard let bookmark = UserDefaults.standard.data(forKey: key) else { return nil }
        var isStale = false
        let folder = try URL(
            resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &isStale
        )
        guard folder.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
        defer { folder.stopAccessingSecurityScopedResource() }
        if isStale { UserDefaults.standard.set(try folder.bookmarkData(options: .withSecurityScope), forKey: key) }
        return try body(folder.appending(path: agent.fileName))
    }

    /// `claudeFolderBookmark` for Claude Code, the key the first version used, so its grant carries over.
    private static func bookmarkKey(_ agent: Agent) -> String {
        agent.rawValue + "FolderBookmark"
    }

    /// The real home folder: inside the sandbox, the home directory APIs point at the app's container.
    private static var home: URL? {
        guard let home = getpwuid(getuid())?.pointee.pw_dir else { return nil }
        return URL(filePath: String(cString: home), directoryHint: .isDirectory)
    }

    private static func message(for error: Error, agent: Agent) -> String {
        switch error as? AgentConfigError {
        case .notASettingsObject, .unreadable:
            String(localized: "\(agent.fileName) couldn't be read, so it was left alone")
        case .notifySlotTaken:
            String(localized: "codex already runs another notify command; remove it from config.toml first")
        case nil:
            error.localizedDescription
        }
    }
}

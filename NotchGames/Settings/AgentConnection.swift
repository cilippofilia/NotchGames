//
//  AgentConnection.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import AppKit
import Observation

/// The link to Claude Code. The sandbox only lets the app into `~/.claude` after the user picks it once, so that grant
/// is kept as a bookmark and the hooks are added and removed through it.
@MainActor @Observable
final class AgentConnection {
    static let shared = AgentConnection()
    /// Pings can be muted without removing the hooks.
    static let enabledKey = "agentPingsEnabled"
    private static let bookmarkKey = "claudeFolderBookmark"

    static var pingsEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    private(set) var isConnected = false
    private(set) var problem: String?

    /// Connected means the hooks are in the file now, so hand edits to it show up here.
    func refresh() {
        isConnected = (try? withFolder { folder in
            try ClaudeHooks.isInstalled(in: try? Data(contentsOf: Self.settingsFile(in: folder)))
        }) ?? false
    }

    func connect() {
        problem = nil
        do {
            if UserDefaults.standard.data(forKey: Self.bookmarkKey) == nil {
                guard try askForFolder() else { return }
            }
            try withFolder { folder in
                let file = Self.settingsFile(in: folder)
                try ClaudeHooks.installing(into: try? Data(contentsOf: file)).write(to: file, options: .atomic)
            }
        } catch {
            problem = Self.message(for: error)
        }
        refresh()
    }

    func disconnect() {
        problem = nil
        do {
            try withFolder { folder in
                let file = Self.settingsFile(in: folder)
                // No file means no hooks: nothing to remove.
                guard let settings = try? Data(contentsOf: file) else { return }
                try ClaudeHooks.removing(from: settings).write(to: file, options: .atomic)
            }
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
        } catch {
            problem = Self.message(for: error)
        }
        refresh()
    }

    /// Returns false when the user cancels.
    private func askForFolder() throws -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.showsHiddenFiles = true
        panel.directoryURL = Self.claudeFolder
        panel.prompt = String(localized: "allow")
        panel.message = String(localized: "allow NotchGames to add its pings to Claude Code's settings in this folder")
        guard panel.runModal() == .OK, let folder = panel.url else { return false }
        guard folder.lastPathComponent == ".claude" else {
            problem = String(localized: "choose the .claude folder in your home folder")
            return false
        }
        let bookmark = try folder.bookmarkData(options: .withSecurityScope)
        UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
        return true
    }

    /// Runs `body` with access to the granted folder; nil when there's no grant yet.
    @discardableResult
    private func withFolder<T>(_ body: (URL) throws -> T) throws -> T? {
        guard let bookmark = UserDefaults.standard.data(forKey: Self.bookmarkKey) else { return nil }
        var isStale = false
        let folder = try URL(
            resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &isStale
        )
        guard folder.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
        defer { folder.stopAccessingSecurityScopedResource() }
        if isStale {
            UserDefaults.standard.set(try folder.bookmarkData(options: .withSecurityScope), forKey: Self.bookmarkKey)
        }
        return try body(folder)
    }

    private static func settingsFile(in folder: URL) -> URL {
        folder.appending(path: "settings.json")
    }

    /// The real `~/.claude`: inside the sandbox, the home directory APIs point at the app's container.
    private static var claudeFolder: URL? {
        guard let home = getpwuid(getuid())?.pointee.pw_dir else { return nil }
        return URL(filePath: String(cString: home), directoryHint: .isDirectory).appending(path: ".claude")
    }

    private static func message(for error: Error) -> String {
        if error is ClaudeHooks.Failure {
            return String(localized: "Claude Code's settings.json isn't valid JSON, so it was left alone")
        }
        return error.localizedDescription
    }
}

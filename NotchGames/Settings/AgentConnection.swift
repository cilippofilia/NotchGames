//
//  AgentConnection.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import AppKit
import Observation

/// The link to the user's coding agents. The sandbox only lets the app into the home folder after the user picks it
/// once, so that grant is kept as a bookmark; through it the app finds which agents are installed and adds or removes
/// the ping in each one's config.
@MainActor @Observable
final class AgentConnection {
    static let shared = AgentConnection()
    /// Pings can be muted without removing any hooks.
    static let enabledKey = "agentPingsEnabled"
    private static let bookmarkKey = "homeFolderBookmark"

    static var pingsEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Installed agents (their folder exists), each of which can be connected on its own.
    private(set) var available: [Agent] = []
    /// Agents whose config has the ping now, so hand edits show up here.
    private(set) var connected: [Agent] = []
    private(set) var problem: String?

    var isConnected: Bool { !connected.isEmpty }

    func refresh() {
        let found = try? withHome { home in
            let available = Agent.allCases.filter { Self.isInstalled($0, in: home) }
            let connected = available.filter { agent in
                (try? agent.isInstalled(in: try? Data(contentsOf: Self.configFile(of: agent, in: home)))) == true
            }
            return (available, connected)
        }
        (available, connected) = found ?? ([], [])
    }

    /// Asks for the home folder if needed, then connects every installed agent.
    func connect() {
        problem = nil
        do {
            if UserDefaults.standard.data(forKey: Self.bookmarkKey) == nil {
                guard try askForHome() else { return }
            }
            let failures = try withHome { home in
                Agent.allCases.filter { Self.isInstalled($0, in: home) }.compactMap { agent in
                    Self.failure(agent) { try Self.install(agent, in: home) }
                }
            }
            refresh()
            if available.isEmpty {
                problem = String(localized: "no claude code, codex or cursor found; copy the command below instead")
            } else if let failures, !failures.isEmpty {
                problem = failures.joined(separator: "\n")
            }
        } catch {
            problem = error.localizedDescription
        }
        refresh()
    }

    /// Connects or disconnects one agent, keeping the others as they are.
    func setConnected(_ agent: Agent, _ isOn: Bool) {
        problem = nil
        do {
            problem = try withHome { home in
                Self.failure(agent) { isOn ? try Self.install(agent, in: home) : try Self.remove(agent, in: home) }
            } ?? nil
        } catch {
            problem = error.localizedDescription
        }
        refresh()
    }

    /// Removes the ping from every agent and forgets the home folder.
    func disconnect() {
        problem = nil
        do {
            let failures = try withHome { home in
                Agent.allCases.compactMap { agent in Self.failure(agent) { try Self.remove(agent, in: home) } }
            } ?? []
            if failures.isEmpty {
                UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
            } else {
                problem = failures.joined(separator: "\n")
            }
        } catch {
            problem = error.localizedDescription
        }
        refresh()
    }

    private static func isInstalled(_ agent: Agent, in home: URL) -> Bool {
        var isFolder: ObjCBool = false
        let folder = home.appending(path: agent.folderName)
        return FileManager.default.fileExists(atPath: folder.path, isDirectory: &isFolder) && isFolder.boolValue
    }

    private static func install(_ agent: Agent, in home: URL) throws {
        let file = configFile(of: agent, in: home)
        try agent.installing(into: try? Data(contentsOf: file)).write(to: file, options: .atomic)
    }

    private static func remove(_ agent: Agent, in home: URL) throws {
        let file = configFile(of: agent, in: home)
        // No file or no ping: nothing to remove, and the file stays untouched.
        guard let config = try? Data(contentsOf: file), try agent.isInstalled(in: config) else { return }
        try agent.removing(from: config).write(to: file, options: .atomic)
    }

    /// Runs one agent's edit and turns an error into a line for the user.
    private static func failure(_ agent: Agent, _ edit: () throws -> Void) -> String? {
        do {
            try edit()
            return nil
        } catch {
            return message(for: error, agent: agent)
        }
    }

    /// Returns false when the user cancels or picks another folder.
    private func askForHome() throws -> Bool {
        guard let home = Self.home else { return false }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = home
        panel.prompt = String(localized: "allow")
        panel.message = String(
            localized: "allow NotchGames to find your coding agents and add its ping to their settings"
        )
        guard panel.runModal() == .OK, let folder = panel.url else { return false }
        guard folder.resolvingSymlinksInPath().path == home.resolvingSymlinksInPath().path else {
            problem = String(localized: "choose your home folder")
            return false
        }
        let bookmark = try folder.bookmarkData(options: .withSecurityScope)
        UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
        return true
    }

    /// Runs `body` with access to the home folder; nil when there's no grant yet.
    @discardableResult
    private func withHome<T>(_ body: (URL) throws -> T) throws -> T? {
        guard let bookmark = UserDefaults.standard.data(forKey: Self.bookmarkKey) else { return nil }
        var isStale = false
        let home = try URL(
            resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &isStale
        )
        guard home.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }
        defer { home.stopAccessingSecurityScopedResource() }
        if isStale {
            UserDefaults.standard.set(try home.bookmarkData(options: .withSecurityScope), forKey: Self.bookmarkKey)
        }
        return try body(home)
    }

    private static func configFile(of agent: Agent, in home: URL) -> URL {
        home.appending(path: agent.folderName).appending(path: agent.fileName)
    }

    /// The real home folder: inside the sandbox, the home directory APIs point at the app's container.
    private static var home: URL? {
        guard let home = getpwuid(getuid())?.pointee.pw_dir else { return nil }
        return URL(filePath: String(cString: home), directoryHint: .isDirectory)
    }

    private static func message(for error: Error, agent: Agent) -> String {
        switch error as? AgentConfigError {
        case .notASettingsObject, .unreadable:
            String(localized: "\(agent.title): \(agent.fileName) couldn't be read, so it was left alone")
        case .notifySlotTaken:
            String(localized: "codex already runs another notify command; remove it from config.toml first")
        case nil:
            "\(agent.title): \(error.localizedDescription)"
        }
    }
}

//
//  CodexNotifyTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation
import Testing
@testable import NotchGames

struct CodexNotifyTests {
    private let config = Data("""
    model = "o4"

    [profiles.fast]
    model = "mini"
    """.utf8)

    private func text(_ data: Data) -> String { String(bytes: data, encoding: .utf8) ?? "" }

    @Test func installingPutsTheNotifyLineAboveEveryTable() throws {
        let installed = text(try CodexNotify.installing(into: config))
        #expect(installed.hasPrefix(CodexNotify.line + "\n"))
        #expect(installed.contains("[profiles.fast]\nmodel = \"mini\""))
        #expect(try CodexNotify.isInstalled(in: Data(installed.utf8)))
    }

    @Test func installingIntoNoFileWritesJustTheLine() throws {
        #expect(text(try CodexNotify.installing(into: nil)) == CodexNotify.line + "\n")
    }

    @Test func installingTwiceAddsOnce() throws {
        let twice = text(try CodexNotify.installing(into: try CodexNotify.installing(into: config)))
        #expect(twice.components(separatedBy: "notchgames://attention").count == 2)
    }

    @Test func removingGivesBackTheOriginal() throws {
        let removed = try CodexNotify.removing(from: try CodexNotify.installing(into: config))
        #expect(text(removed) == text(config))
        #expect(try !CodexNotify.isInstalled(in: removed))
    }

    @Test func refusesToReplaceSomeoneElsesNotify() {
        let taken = Data("notify = [\"terminal-notifier\"]\nmodel = \"o4\"\n".utf8)
        #expect(throws: AgentConfigError.notifySlotTaken) { try CodexNotify.installing(into: taken) }
    }

    @Test func aNotifyKeyInsideATableIsntTheTopLevelOne() throws {
        let tabled = Data("[tui]\nnotify = true\n".utf8)
        #expect(try CodexNotify.isInstalled(in: try CodexNotify.installing(into: tabled)))
    }
}

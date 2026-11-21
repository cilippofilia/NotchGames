//
//  ClaudeHooksTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation
import Testing
@testable import NotchGames

struct ClaudeHooksTests {
    private let otherSettings = Data("""
    {"model": "opus", "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "say done"}]}]}}
    """.utf8)

    private func object(_ data: Data) throws -> NSDictionary {
        try #require(try JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }

    @Test func installingIntoNoFileAddsBothEvents() throws {
        let installed = try ClaudeHooks.installing(into: nil)
        #expect(try ClaudeHooks.isInstalled(in: installed))
        let hooks = try #require(try object(installed)["hooks"] as? [String: [[String: Any]]])
        for event in ["Notification", "Stop"] {
            let command = (hooks[event]?.first?["hooks"] as? [[String: Any]])?.first?["command"] as? String
            #expect(command == ClaudeHooks.command)
        }
    }

    @Test func installingKeepsOtherSettingsAndHooks() throws {
        let installed = try object(try ClaudeHooks.installing(into: otherSettings))
        #expect(installed["model"] as? String == "opus")
        let stop = try #require((installed["hooks"] as? [String: Any])?["Stop"] as? [Any])
        #expect(stop.count == 2)
    }

    @Test func installingTwiceAddsOnce() throws {
        let twice = try ClaudeHooks.installing(into: try ClaudeHooks.installing(into: otherSettings))
        let stop = try #require((try object(twice)["hooks"] as? [String: Any])?["Stop"] as? [Any])
        #expect(stop.count == 2)
    }

    @Test func removingLeavesEverythingElseAsItWas() throws {
        let removed = try ClaudeHooks.removing(from: try ClaudeHooks.installing(into: otherSettings))
        #expect(try object(removed) == (try object(otherSettings)))
        #expect(try !ClaudeHooks.isInstalled(in: removed))
    }

    @Test func removingTheOnlyHooksDropsTheHooksKey() throws {
        let removed = try ClaudeHooks.removing(from: try ClaudeHooks.installing(into: nil))
        #expect(try object(removed).count == 0)
    }

    @Test func recognisesHooksAddedByHand() throws {
        let byHand = Data("""
        {"hooks": {"Notification": [{"hooks": [{"type": "command", "command": "open -g notchgames://attention"}]}],
                   "Stop": [{"hooks": [{"type": "command", "command": "open -g notchgames://attention"}]}]}}
        """.utf8)
        #expect(try ClaudeHooks.isInstalled(in: byHand))
    }

    @Test func halfInstalledIsNotInstalled() throws {
        #expect(try !ClaudeHooks.isInstalled(in: nil))
        let stopOnly = Data("""
        {"hooks": {"Stop": [{"hooks": [{"type": "command", "command": "open -g notchgames://attention"}]}]}}
        """.utf8)
        #expect(try !ClaudeHooks.isInstalled(in: stopOnly))
    }

    @Test(arguments: ["[1]", "not json"])
    func refusesToRewriteAFileThatIsntASettingsObject(contents: String) {
        #expect(throws: (any Error).self) { try ClaudeHooks.installing(into: Data(contents.utf8)) }
    }
}

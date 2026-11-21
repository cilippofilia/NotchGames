//
//  CursorHooksTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation
import Testing
@testable import NotchGames

struct CursorHooksTests {
    private let otherHooks = Data("""
    {"version": 1, "hooks": {"stop": [{"command": "./audit.sh"}], "beforeShellExecution": [{"command": "./guard.sh"}]}}
    """.utf8)

    private func object(_ data: Data) throws -> NSDictionary {
        try #require(try JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }

    @Test func installingIntoNoFileAddsAVersionedStopHook() throws {
        let installed = try object(try CursorHooks.installing(into: nil))
        #expect(installed["version"] as? Int == 1)
        let stop = (installed["hooks"] as? [String: Any])?["stop"] as? [[String: Any]]
        #expect(stop?.first?["command"] as? String == ClaudeHooks.command)
    }

    @Test func installingKeepsOtherHooks() throws {
        let installed = try object(try CursorHooks.installing(into: otherHooks))
        let hooks = try #require(installed["hooks"] as? [String: [Any]])
        #expect(hooks["stop"]?.count == 2)
        #expect(hooks["beforeShellExecution"]?.count == 1)
    }

    @Test func installingTwiceAddsOnce() throws {
        let twice = try CursorHooks.installing(into: try CursorHooks.installing(into: otherHooks))
        #expect(((try object(twice)["hooks"] as? [String: [Any]])?["stop"])?.count == 2)
    }

    @Test func removingLeavesEverythingElseAsItWas() throws {
        let removed = try CursorHooks.removing(from: try CursorHooks.installing(into: otherHooks))
        #expect(try object(removed) == (try object(otherHooks)))
        #expect(try !CursorHooks.isInstalled(in: removed))
    }
}

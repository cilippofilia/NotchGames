//
//  SettingsTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import AppKit
import Foundation
import Testing
@testable import NotchGames

struct SettingsTests {
    private func freshDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "SettingsTests-\(UUID())"))
    }

    @Test func airHockeyStartsFromTheSharedDifficulty() throws {
        let defaults = try freshDefaults()
        defaults.set(Difficulty.hard.rawValue, forKey: Difficulty.storageKey(for: .pong))
        Difficulty.copySharedChoice(in: defaults)
        #expect(defaults.string(forKey: Difficulty.storageKey(for: .airHockey)) == Difficulty.hard.rawValue)
    }

    @Test func airHockeyKeepsItsOwnDifficulty() throws {
        let defaults = try freshDefaults()
        defaults.set(Difficulty.hard.rawValue, forKey: Difficulty.storageKey(for: .pong))
        defaults.set(Difficulty.easy.rawValue, forKey: Difficulty.storageKey(for: .airHockey))
        Difficulty.copySharedChoice(in: defaults)
        #expect(defaults.string(forKey: Difficulty.storageKey(for: .airHockey)) == Difficulty.easy.rawValue)
    }

    @Test func nothingToCopyWhenNoDifficultyWasChosen() throws {
        let defaults = try freshDefaults()
        Difficulty.copySharedChoice(in: defaults)
        #expect(defaults.object(forKey: Difficulty.storageKey(for: .airHockey)) == nil)
    }

    @Test func pongKeepsTheOriginalKey() {
        #expect(Difficulty.storageKey(for: .pong) == "difficulty")
        #expect(Difficulty.storageKey(for: .airHockey) != "difficulty")
    }

    @Test(arguments: GameKind.allCases)
    func everyGameTabHasARealIcon(game: GameKind) {
        #expect(NSImage(systemSymbolName: game.symbolName, accessibilityDescription: nil) != nil)
    }
}

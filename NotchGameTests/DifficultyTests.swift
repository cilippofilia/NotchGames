//
//  DifficultyTests.swift
//  NotchGameTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGame

struct DifficultyTests {
    @Test func moderateIsTheDefaultAndMatchesTodaysTuning() {
        #expect(Difficulty.standard == .moderate)
        let opponent = ComputerOpponent(difficulty: .moderate)
        #expect(opponent.maxSpeed == 0.55)
        #expect(opponent.reactionDelay == 0.2)
    }

    @Test func eachLevelIsFasterAndQuickerThanTheOneBefore() {
        let levels = Difficulty.allCases.map { ComputerOpponent(difficulty: $0) }
        for (easier, harder) in zip(levels, levels.dropFirst()) {
            #expect(harder.maxSpeed > easier.maxSpeed)
            #expect(harder.reactionDelay < easier.reactionDelay)
        }
    }

    @Test func gameUsesTheChosenDifficulty() {
        let game = PongGame()
        game.difficulty = .expert
        #expect(game.opponentSpeed == ComputerOpponent(difficulty: .expert).maxSpeed)
        game.reset()
        #expect(game.opponentSpeed == ComputerOpponent(difficulty: .expert).maxSpeed)
    }
}

//
//  RunResult.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/3/26.
//

/// How a score-based run ended, for the game-over message.
nonisolated struct RunResult: Equatable {
    let score: Int
    let best: Int
    let isNewBest: Bool
}

//
//  PlayerStats.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

/// The player's record against the computer.
nonisolated struct PlayerStats: Codable, Equatable {
    var wins = 0
    var losses = 0
    /// Wins in a row right now.
    var currentStreak = 0
    var bestStreak = 0

    mutating func record(winner: PongSide) {
        switch winner {
        case .player:
            wins += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        case .computer:
            losses += 1
            currentStreak = 0
        }
    }
}

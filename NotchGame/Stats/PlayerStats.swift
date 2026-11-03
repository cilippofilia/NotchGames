//
//  PlayerStats.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

/// The player's record against the computer, and the best score in each score-based game.
nonisolated struct PlayerStats: Codable, Equatable {
    var wins = 0
    var losses = 0
    /// Wins in a row right now.
    var currentStreak = 0
    var bestStreak = 0
    /// Keyed by `GameKind.rawValue`.
    var bestScores: [String: Int] = [:]

    init(wins: Int = 0, losses: Int = 0, currentStreak: Int = 0, bestStreak: Int = 0, bestScores: [String: Int] = [:]) {
        self.wins = wins
        self.losses = losses
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.bestScores = bestScores
    }

    /// Records saved before best scores existed have no `bestScores` key; they must still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wins = try container.decode(Int.self, forKey: .wins)
        losses = try container.decode(Int.self, forKey: .losses)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        bestStreak = try container.decode(Int.self, forKey: .bestStreak)
        bestScores = try container.decodeIfPresent([String: Int].self, forKey: .bestScores) ?? [:]
    }

    func bestScore(for game: GameKind) -> Int {
        bestScores[game.rawValue] ?? 0
    }

    /// Returns true when `score` beats the saved best, which then becomes the new best.
    mutating func recordScore(_ score: Int, for game: GameKind) -> Bool {
        guard score > bestScore(for: game) else { return false }
        bestScores[game.rawValue] = score
        return true
    }

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

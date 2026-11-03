//
//  PlayerStats.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

/// The player's record against the computer in each match game, and the best score in each score-based game.
nonisolated struct PlayerStats: Codable, Equatable {
    /// Keyed by `GameKind.rawValue`.
    var matchRecords: [String: MatchRecord] = [:]
    /// Keyed by `GameKind.rawValue`.
    var bestScores: [String: Int] = [:]

    private enum CodingKeys: String, CodingKey {
        case matchRecords, bestScores
        // Before records were per game, one shared record sat at the top level; it now belongs to Pong.
        case wins, losses, currentStreak, bestStreak
    }

    init(matchRecords: [String: MatchRecord] = [:], bestScores: [String: Int] = [:]) {
        self.matchRecords = matchRecords
        self.bestScores = bestScores
    }

    /// Loads every saved format. A decoding error would wipe the whole record, so older keys are all optional.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bestScores = try container.decodeIfPresent([String: Int].self, forKey: .bestScores) ?? [:]
        if let records = try container.decodeIfPresent([String: MatchRecord].self, forKey: .matchRecords) {
            matchRecords = records
        } else if let wins = try container.decodeIfPresent(Int.self, forKey: .wins) {
            matchRecords[GameKind.pong.rawValue] = MatchRecord(
                wins: wins,
                losses: try container.decodeIfPresent(Int.self, forKey: .losses) ?? 0,
                currentStreak: try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0,
                bestStreak: try container.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
            )
        }
    }

    /// Writes only the current format, so the old shared record never comes back.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(matchRecords, forKey: .matchRecords)
        try container.encode(bestScores, forKey: .bestScores)
    }

    func matchRecord(for game: GameKind) -> MatchRecord {
        matchRecords[game.rawValue] ?? MatchRecord()
    }

    mutating func record(winner: PongSide, for game: GameKind) {
        matchRecords[game.rawValue, default: MatchRecord()].record(winner: winner)
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

    /// Clears one game's record and best score.
    mutating func reset(_ game: GameKind) {
        matchRecords[game.rawValue] = nil
        bestScores[game.rawValue] = nil
    }
}

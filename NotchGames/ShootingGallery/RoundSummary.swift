//
//  RoundSummary.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

/// A passed round, shown between rounds until the player is ready for the next one.
nonisolated struct RoundSummary: Equatable {
    let round: Int
    let hits: Int
    /// Points for a perfect round, or 0.
    let bonus: Int
    /// Hits needed to pass the next round.
    let nextQuota: Int
}

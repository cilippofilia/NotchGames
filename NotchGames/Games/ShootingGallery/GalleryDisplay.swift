//
//  GalleryDisplay.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

/// What the views around the shooting gallery show. Republished only when it changes,
/// so those views rebuild on events rather than on every frame.
nonisolated struct GalleryDisplay: Equatable {
    var run = RunDisplay()
    var round = 1
    var quota = 6
    /// Hit or missed for each bird so far this round.
    var results: [Bool] = []
    var shotsLeft = GalleryModel.shotsPerWave
    /// The round just passed, while the game waits between rounds.
    var summary: RoundSummary?
}

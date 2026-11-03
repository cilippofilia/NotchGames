//
//  SnakeDisplay.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

/// What the views around the snake grid show. Republished only when it changes,
/// so those views rebuild on events rather than on every frame.
nonisolated struct SnakeDisplay: Equatable {
    var isPaused = true
    /// Whole seconds left in the countdown, rounded up; 0 once the snake is moving.
    var countdownSeconds = 0
    var score = 0
    var isOver = false
    var best = 0
    var isNewBest = false
}

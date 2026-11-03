//
//  BrickBreakerDisplay.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/3/26.
//

/// What the views around the brick breaker court show. Republished only when it changes,
/// so those views rebuild on events rather than on every frame.
nonisolated struct BrickBreakerDisplay: Equatable {
    var isPaused = true
    /// Whole seconds left in the countdown, rounded up; 0 once the ball is in play.
    var countdownSeconds = 0
    var score = 0
    var lives = BrickBreakerModel.startingLives
    var isOver = false
    var best = 0
    var isNewBest = false
}

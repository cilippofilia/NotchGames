//
//  MatchDisplay.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/3/26.
//

/// What the views around the court show. Games republish it only when it changes, so those views
/// rebuild on events (a point, a pause, a countdown tick) rather than on every frame.
nonisolated struct MatchDisplay: Equatable {
    var isPaused = true
    /// Whole seconds left in the countdown, rounded up; 0 once the ball is in play.
    var countdownSeconds = 0
    var computerScore = 0
    var playerScore = 0
    var winner: PongSide?
}

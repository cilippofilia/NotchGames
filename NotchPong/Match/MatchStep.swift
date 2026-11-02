//
//  MatchStep.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation

/// What a game should do on this frame.
nonisolated enum MatchStep: Equatable {
    /// Paused, or the first frame after resuming: nothing moves.
    case waiting
    case countingDown
    /// The countdown just reached zero; play starts next frame.
    case countdownFinished
    /// Simulate this much time.
    case playing(TimeInterval)
}

//
//  MatchClock.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation

/// The pause, countdown and frame timing every game shares. A countdown runs at the start, whenever play resumes
/// after a pause, and whenever a game asks for one (after a point).
nonisolated struct MatchClock {
    static let countdownLength: TimeInterval = 3
    /// Longest step simulated at once, so a late frame can't teleport anything.
    static let maxStep: TimeInterval = 1.0 / 30

    var isPaused = true {
        didSet {
            if isPaused {
                lastTick = nil
            } else if oldValue {
                countdown = Self.countdownLength
            }
        }
    }
    /// Seconds left before play.
    private(set) var countdown: TimeInterval = 0
    private var lastTick: Date?

    mutating func startCountdown() {
        countdown = Self.countdownLength
    }

    mutating func advance(to now: Date) -> MatchStep {
        guard !isPaused else {
            lastTick = nil
            return .waiting
        }
        // The first frame after a pause only starts the clock, so nothing jumps.
        guard let lastTick else {
            self.lastTick = now
            return .waiting
        }
        self.lastTick = now
        let elapsed = now.timeIntervalSince(lastTick)
        guard countdown <= 0 else {
            countdown = max(countdown - elapsed, 0)
            return countdown > 0 ? .countingDown : .countdownFinished
        }
        return .playing(min(elapsed, Self.maxStep))
    }
}

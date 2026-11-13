//
//  SnakeGame.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import Foundation
import Observation

/// Runs a snake run: keys only. An arrow or W/A/S/D starts or resumes it (through the countdown), space pauses,
/// and return plays again once it's over. The snake steps on a timer that speeds up as it grows.
@MainActor
@Observable
final class SnakeGame {
    static let countdownLength = MatchClock.countdownLength
    /// Where the walls setting is saved in user defaults. On by default, like the classic.
    static let wallsStorageKey = "snakeWalls"

    // The model and clock change every frame; views redraw from their own timeline and read `display`.
    @ObservationIgnored private(set) var model: SnakeModel
    @ObservationIgnored private var clock = MatchClock()
    /// Score, pause and countdown, republished only when one of them changes.
    private(set) var display = RunDisplay()
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private var sinceStep: TimeInterval = 0
    @ObservationIgnored private var isNewBest = false
    @ObservationIgnored private var generator = SystemRandomNumberGenerator()

    var hasWalls: Bool {
        get { model.hasWalls }
        set { model.hasWalls = newValue }
    }
    var isPaused: Bool {
        get { clock.isPaused }
        set {
            clock.isPaused = newValue
            publishDisplay()
        }
    }
    var countdown: TimeInterval { clock.countdown }

    init(model: SnakeModel = SnakeModel(), stats: StatsStore = .shared) {
        self.model = model
        self.stats = stats
        publishDisplay()
    }

    func reset() {
        model = SnakeModel(hasWalls: model.hasWalls, generator: &generator)
        clock = MatchClock()
        sinceStep = 0
        isNewBest = false
        publishDisplay()
    }

    /// An arrow or W/A/S/D went down: steer, and start a waiting run.
    func press(_ direction: HeldKeys.Direction) {
        guard !model.isOver else { return }
        model.turn(direction)
        isPaused = false
    }

    /// Space: pause, or resume through the countdown.
    func togglePause() {
        guard !model.isOver else { return }
        isPaused.toggle()
    }

    func tick(now: Date) {
        defer { publishDisplay() }
        guard case .playing(let interval) = clock.advance(to: now), !model.isOver else { return }
        // Frames are capped at 1/30 s, so a step shorter than a frame still runs: catch up in a loop.
        sinceStep += interval
        while sinceStep >= model.stepInterval, !model.isOver {
            sinceStep -= model.stepInterval
            model.step(generator: &generator)
        }
        if model.isOver {
            isNewBest = stats.recordScore(model.score, for: .snake)
        }
    }

    private func publishDisplay() {
        let latest = RunDisplay(
            isPaused: clock.isPaused,
            countdownSeconds: Int(clock.countdown.rounded(.up)),
            score: model.score,
            isOver: model.isOver,
            best: stats.stats.bestScore(for: .snake),
            isNewBest: isNewBest
        )
        if latest != display { display = latest }
    }
}

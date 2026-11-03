//
//  RunnerGame.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import Foundation
import Observation

/// Runs a runner run: keys only. Jump (space, up, W) starts or resumes it through the countdown, duck is down or S,
/// escape pauses, and return plays again once it's over.
@MainActor
@Observable
final class RunnerGame {
    static let countdownLength = MatchClock.countdownLength

    // The model and clock change every frame; the court redraws from its own timeline and views read `display`.
    @ObservationIgnored private(set) var model = RunnerModel()
    @ObservationIgnored private var clock = MatchClock()
    private(set) var display = RunDisplay()
    /// Whether jump and duck are held right now.
    @ObservationIgnored var isJumpHeld = false
    @ObservationIgnored var isDuckHeld = false
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private var isNewBest = false
    @ObservationIgnored private var generator = SystemRandomNumberGenerator()

    var isPaused: Bool {
        get { clock.isPaused }
        set {
            clock.isPaused = newValue
            publishDisplay()
        }
    }
    var countdown: TimeInterval { clock.countdown }

    init(model: RunnerModel = RunnerModel(), stats: StatsStore = .shared) {
        self.model = model
        self.stats = stats
        publishDisplay()
    }

    func reset() {
        model = RunnerModel()
        clock = MatchClock()
        isNewBest = false
        publishDisplay()
    }

    /// Jump went down: starts a waiting run. The jump itself happens in `tick` while the key stays held.
    func jumpPressed() {
        guard !model.isOver else { return }
        isPaused = false
    }

    /// Escape: pause, or resume through the countdown.
    func togglePause() {
        guard !model.isOver else { return }
        isPaused.toggle()
    }

    /// Key-ups go elsewhere once focus moves on, so forget held keys rather than keep jumping.
    func releaseKeys() {
        isJumpHeld = false
        isDuckHeld = false
    }

    func tick(now: Date) {
        defer { publishDisplay() }
        guard case .playing(let interval) = clock.advance(to: now), !model.isOver else { return }
        model.step(by: interval, jump: isJumpHeld, duck: isDuckHeld, generator: &generator)
        if model.isOver {
            isNewBest = stats.recordScore(model.score, for: .runner)
        }
    }

    private func publishDisplay() {
        let latest = RunDisplay(
            isPaused: clock.isPaused,
            countdownSeconds: Int(clock.countdown.rounded(.up)),
            score: model.score,
            isOver: model.isOver,
            best: stats.stats.bestScore(for: .runner),
            isNewBest: isNewBest
        )
        if latest != display { display = latest }
    }
}

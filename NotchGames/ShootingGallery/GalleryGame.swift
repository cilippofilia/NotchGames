//
//  GalleryGame.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation
import Observation

/// Runs a shooting gallery run: pointer only. The pointer aims, a click shoots. Like Pong, it pauses when the
/// pointer leaves the panel and resumes through the countdown when it comes back. Between rounds it waits on a
/// summary until the player asks for the next round, which then counts in.
@MainActor
@Observable
final class GalleryGame {
    static let countdownLength = MatchClock.countdownLength

    // The model and clock change every frame; the court redraws from its own timeline and views read `display`.
    @ObservationIgnored private(set) var model = GalleryModel()
    @ObservationIgnored private var clock = MatchClock()
    private(set) var display = GalleryDisplay()
    /// The latest hit, for its spark (court units).
    @ObservationIgnored private(set) var lastHit: WallHit?
    /// When the latest shot was fired, for its flash.
    @ObservationIgnored private(set) var lastShotTime: Date?
    /// The latest miss, for the ring where it landed (court units).
    @ObservationIgnored private(set) var lastMiss: WallHit?
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private var isNewBest = false
    /// The round just passed, shown until the player continues; the game stays paused meanwhile.
    @ObservationIgnored private var summary: RoundSummary?
    @ObservationIgnored private var generator = SystemRandomNumberGenerator()

    var isPaused: Bool {
        get { clock.isPaused }
        set {
            clock.isPaused = newValue
            publishDisplay()
        }
    }
    var countdown: TimeInterval { clock.countdown }
    /// Shots only count while birds are in play: not while paused or counting down.
    var canShoot: Bool { !isPaused && countdown <= 0 && !model.isOver }

    init(model: GalleryModel = GalleryModel(), stats: StatsStore = .shared) {
        self.model = model
        self.stats = stats
        publishDisplay()
    }

    func reset() {
        model = GalleryModel()
        clock = MatchClock()
        lastHit = nil
        lastShotTime = nil
        lastMiss = nil
        isNewBest = false
        summary = nil
        publishDisplay()
    }

    /// A click at `point` (court units).
    func shoot(at point: CGPoint, now: Date) {
        guard canShoot else { return }
        let shotsBefore = model.shotsLeft
        let hit = model.shoot(at: point)
        // A click with no birds up (between pairs) isn't a shot.
        guard model.shotsLeft != shotsBefore else { return }
        lastShotTime = now
        let event = WallHit(position: point, inward: CGVector(dx: 0, dy: -1), time: now)
        if hit {
            lastHit = event
        } else {
            lastMiss = event
        }
        publishDisplay()
    }

    /// Same rule as Pong: only the panel itself starts a paused game; the gutter keeps a running one going.
    func pointerMoved(insidePanel: Bool?) {
        guard let insidePanel else {
            isPaused = true
            return
        }
        if isPaused, !insidePanel { return }
        // Between rounds, only the player's go-ahead starts the next one.
        if !model.isOver, summary == nil { isPaused = false }
    }

    func tick(now: Date) {
        defer { publishDisplay() }
        guard case .playing(let interval) = clock.advance(to: now), !model.isOver else { return }
        model.step(by: interval, generator: &generator)
        if let passed = model.passedRound {
            summary = passed
            isPaused = true
        } else if model.isOver {
            isNewBest = stats.recordScore(model.score, for: .shootingGallery)
        }
    }

    /// "next round": leave the summary and count the next round in.
    func continueToNextRound() {
        guard summary != nil else { return }
        summary = nil
        isPaused = false
    }

    private func publishDisplay() {
        let latest = GalleryDisplay(
            run: RunDisplay(
                isPaused: clock.isPaused,
                countdownSeconds: Int(clock.countdown.rounded(.up)),
                score: model.score,
                isOver: model.isOver,
                best: stats.stats.bestScore(for: .shootingGallery),
                isNewBest: isNewBest
            ),
            round: model.round,
            quota: model.quota,
            results: model.results,
            shotsLeft: model.shotsLeft,
            summary: summary
        )
        if latest != display { display = latest }
    }
}

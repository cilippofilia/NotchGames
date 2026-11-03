//
//  BrickBreakerGame.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation
import Observation

/// Runs a brick breaker run: frame timing, dropping rows on a timer, survival points, lives, and the best score.
@MainActor
@Observable
final class BrickBreakerGame {
    static let countdownLength = MatchClock.countdownLength
    /// How long a new row takes to slide into place.
    private static let slideDuration: TimeInterval = 0.25

    // The model, clock, timers and trail change every frame. They're ignored so views don't rebuild per frame:
    // the court redraws from its own timeline, and everything else reads `display`.
    @ObservationIgnored private(set) var model: BrickBreakerModel
    @ObservationIgnored private var clock = MatchClock()
    /// Score, lives, pause and countdown, republished only when one of them changes.
    private(set) var display = BrickBreakerDisplay()
    @ObservationIgnored private(set) var ballTrail: [(position: CGPoint, time: Date)] = []
    /// 1 right after a row drops, easing to 0 as it slides into place.
    @ObservationIgnored private(set) var rowSlide: CGFloat = 0
    private(set) var lastWallHit: WallHit?
    private(set) var lastBrickHit: WallHit?
    @ObservationIgnored private let stats: StatsStore
    @ObservationIgnored private var rowTimer: TimeInterval = 0
    @ObservationIgnored private var playTime: TimeInterval = 0
    /// Where the player last aimed while the paddle was frozen; applied when play starts.
    @ObservationIgnored private var pendingAim: CGFloat?
    @ObservationIgnored private var isNewBest = false

    var isPaused: Bool {
        get { clock.isPaused }
        set {
            clock.isPaused = newValue
            publishDisplay()
        }
    }
    var countdown: TimeInterval { clock.countdown }
    /// The paddle only moves while the ball is in play: not while paused or counting down.
    var paddleCanMove: Bool { !isPaused && countdown <= 0 }

    init(model: BrickBreakerModel = BrickBreakerModel(), stats: StatsStore = .shared) {
        self.model = model
        self.stats = stats
        publishDisplay()
    }

    func reset() {
        model = BrickBreakerModel()
        clock = MatchClock()
        ballTrail = []
        rowSlide = 0
        lastWallHit = nil
        lastBrickHit = nil
        rowTimer = 0
        playTime = 0
        pendingAim = nil
        isNewBest = false
        publishDisplay()
    }

    func tick(now: Date) {
        defer { publishDisplay() }
        let interval: TimeInterval
        switch clock.advance(to: now) {
        case .waiting, .countingDown:
            return
        case .countdownFinished:
            if let pendingAim { aim(atCourtX: pendingAim) }
            pendingAim = nil
            return
        case .playing(let step):
            interval = step
        }
        guard !model.isOver else { return }

        let ballBefore = model.ball.position
        model.step(by: interval)
        ballTrail.append((ballBefore, now))
        ballTrail.removeAll { now.timeIntervalSince($0.time) > PongGame.trailLength }
        if let bounce = model.wallBounce {
            lastWallHit = WallHit(position: bounce.position, inward: bounce.inward, time: now)
        }
        if let brick = model.brokenBrick {
            let center = CGPoint(x: brick.midX, y: brick.midY)
            lastBrickHit = WallHit(position: center, inward: CGVector(dx: 0, dy: 1), time: now)
        }

        rowSlide = max(rowSlide - CGFloat(interval / Self.slideDuration), 0)
        rowTimer += interval
        if rowTimer >= model.rowInterval {
            rowTimer = 0
            model.dropRow()
            rowSlide = 1
        }
        let wholeSeconds = Int(playTime)
        playTime += interval
        model.addSurvivalPoints(Int(playTime) - wholeSeconds)

        if model.isOver {
            isNewBest = stats.recordScore(model.score, for: .brickBreaker)
        } else if model.lostBall {
            // A served ball's old trail would streak down from where it was lost.
            ballTrail = []
            clock.startCountdown()
        }
    }

    /// `courtX` in court units; the paddle stays inside the court.
    func aim(atCourtX courtX: CGFloat) {
        if paddleCanMove {
            model.paddleX = BrickBreakerModel.clampedPaddleX(courtX)
        } else {
            pendingAim = courtX
        }
    }

    func nudge(by delta: CGFloat) {
        aim(atCourtX: (pendingAim ?? model.paddleX) + delta)
    }

    /// Same rule as Pong: only the panel itself starts a paused game; the gutter keeps a running one going.
    func pointerMoved(toCourtX courtX: CGFloat?, insidePanel: Bool) {
        guard let courtX else {
            isPaused = true
            return
        }
        if isPaused, !insidePanel { return }
        aim(atCourtX: courtX)
        if !model.isOver { isPaused = false }
    }

    private func publishDisplay() {
        let latest = BrickBreakerDisplay(
            isPaused: clock.isPaused,
            countdownSeconds: Int(clock.countdown.rounded(.up)),
            score: model.score,
            lives: model.lives,
            isOver: model.isOver,
            best: stats.stats.bestScore(for: .brickBreaker),
            isNewBest: isNewBest
        )
        if latest != display { display = latest }
    }
}

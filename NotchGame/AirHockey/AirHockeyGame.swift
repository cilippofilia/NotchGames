//
//  AirHockeyGame.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Observation

/// Runs an air hockey match: frame timing, the computer, the player's aim, and the
/// points and wall hits the view turns into effects.
@MainActor
@Observable
final class AirHockeyGame {
    // The model, clock and trail change every frame. They're ignored so views don't rebuild per frame:
    // the rink redraws from its own timeline, and everything else reads `display`.
    @ObservationIgnored private(set) var model: AirHockeyModel
    @ObservationIgnored private var clock = MatchClock()
    /// Paused, countdown, scores and winner, republished only when one of them changes.
    private(set) var display = MatchDisplay()
    private(set) var lastPoint: PointEvent?
    private(set) var lastWallHit: WallHit?
    /// The puck's recent positions, oldest first, for its trail.
    @ObservationIgnored private(set) var puckTrail: [(position: CGPoint, time: Date)] = []
    var difficulty = Difficulty.standard
    /// Called once when a match is decided, with the side that won.
    @ObservationIgnored var onMatchEnd: ((PongSide) -> Void)?
    /// Where the player's mallet is being steered, in court units.
    @ObservationIgnored private var playerAim: CGPoint

    /// The computer's mallet speed, scaled from the Pong paddle speed because it covers a whole half-court.
    private static let speedScale: CGFloat = 2.4

    var isPaused: Bool {
        get { clock.isPaused }
        set {
            clock.isPaused = newValue
            publishDisplay()
        }
    }
    var countdown: TimeInterval { clock.countdown }
    var winner: PongSide? { model.winner }

    init(model: AirHockeyModel = AirHockeyModel()) {
        self.model = model
        playerAim = model.playerMallet
        publishDisplay()
    }

    func reset() {
        model = AirHockeyModel()
        clock = MatchClock()
        lastPoint = nil
        lastWallHit = nil
        puckTrail = []
        playerAim = model.playerMallet
        publishDisplay()
    }

    private func publishDisplay() {
        let latest = MatchDisplay(
            isPaused: clock.isPaused,
            countdownSeconds: Int(clock.countdown.rounded(.up)),
            computerScore: model.computerScore,
            playerScore: model.playerScore,
            winner: model.winner
        )
        if latest != display { display = latest }
    }

    func tick(now: Date) {
        defer { publishDisplay() }
        guard case .playing(let interval) = clock.advance(to: now) else { return }
        let computerTarget = AirHockeyOpponent.target(puck: model.puck, mallet: model.computerMallet)
        let puckBefore = model.puck.position
        let scoresBefore = (model.playerScore, model.computerScore)
        model.step(
            by: interval,
            playerTarget: playerAim,
            computerTarget: computerTarget,
            computerSpeed: difficulty.opponentSpeed * Self.speedScale
        )
        puckTrail.append((puckBefore, now))
        puckTrail.removeAll { now.timeIntervalSince($0.time) > PongGame.trailLength }
        if let bounce = model.wallBounce {
            lastWallHit = WallHit(position: bounce.position, inward: bounce.inward, time: now)
        }
        guard (model.playerScore, model.computerScore) != scoresBefore else { return }
        // The puck is back at the center, so its old trail would streak across the rink.
        puckTrail = []
        let side: PongSide = model.playerScore != scoresBefore.0 ? .player : .computer
        lastPoint = PointEvent(
            side: side,
            position: CGPoint(x: side == .computer ? AirHockeyModel.courtSize.width : 0, y: puckBefore.y),
            time: now
        )
        if let winner = model.winner {
            onMatchEnd?(winner)
        } else {
            clock.startCountdown()
        }
    }

    /// Steers the player's mallet (court units). It only moves during play; while paused or counting down
    /// it holds still and catches up once play starts.
    func aim(at point: CGPoint) {
        playerAim = point
    }

    func nudgeAim(by delta: CGVector) {
        aim(at: CGPoint(x: playerAim.x + delta.dx, y: playerAim.y + delta.dy))
    }

    /// Same rule as Pong: only the panel itself starts a paused game; the gutter keeps a running one going.
    func pointerMoved(to courtPoint: CGPoint?, insidePanel: Bool) {
        guard let courtPoint else {
            isPaused = true
            return
        }
        if isPaused, !insidePanel { return }
        aim(at: courtPoint)
        if model.winner == nil { isPaused = false }
    }
}

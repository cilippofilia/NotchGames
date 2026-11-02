//
//  AirHockeyGame.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Observation

/// Runs an air hockey match: frame timing, the computer (or second player), the player's aim, and the
/// points and wall hits the view turns into effects.
@MainActor
@Observable
final class AirHockeyGame {
    private(set) var model: AirHockeyModel
    private var clock = MatchClock()
    private(set) var lastPoint: PointEvent?
    private(set) var lastWallHit: WallHit?
    var difficulty = Difficulty.standard
    var playerCount = PlayerCount.standard
    /// Called once when a match is decided, with the side that won.
    @ObservationIgnored var onMatchEnd: ((PongSide) -> Void)?
    /// Where each mallet is being steered, in court units.
    @ObservationIgnored private var playerAim: CGPoint
    @ObservationIgnored private var leftAim: CGPoint

    /// The computer's mallet speed, scaled from the Pong paddle speed because it covers a whole half-court.
    private static let speedScale: CGFloat = 2.4

    var isPaused: Bool {
        get { clock.isPaused }
        set { clock.isPaused = newValue }
    }
    var countdown: TimeInterval { clock.countdown }
    var winner: PongSide? { model.winner }

    init(model: AirHockeyModel = AirHockeyModel()) {
        self.model = model
        playerAim = model.playerMallet
        leftAim = model.computerMallet
    }

    func reset() {
        model = AirHockeyModel()
        clock = MatchClock()
        lastPoint = nil
        lastWallHit = nil
        playerAim = model.playerMallet
        leftAim = model.computerMallet
    }

    func tick(now: Date) {
        guard case .playing(let interval) = clock.advance(to: now) else { return }
        let computerTarget = playerCount == .one
            ? AirHockeyOpponent.target(puck: model.puck, mallet: model.computerMallet)
            : leftAim
        let puckBefore = model.puck.position
        let scoresBefore = (model.playerScore, model.computerScore)
        model.step(
            by: interval,
            playerTarget: playerAim,
            computerTarget: computerTarget,
            computerSpeed: difficulty.opponentSpeed * Self.speedScale
        )
        if let bounce = model.wallBounce {
            lastWallHit = WallHit(position: bounce.position, inward: bounce.inward, time: now)
        }
        guard (model.playerScore, model.computerScore) != scoresBefore else { return }
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

    /// The second player's mallet in two-player mode.
    func aimLeft(at point: CGPoint) {
        leftAim = point
    }

    func nudgeAim(by delta: CGVector) {
        aim(at: CGPoint(x: playerAim.x + delta.dx, y: playerAim.y + delta.dy))
    }

    func nudgeLeftAim(by delta: CGVector) {
        aimLeft(at: CGPoint(x: leftAim.x + delta.dx, y: leftAim.y + delta.dy))
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

//
//  ComputerOpponent.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// Moves the left paddle like a player working the shot out: it follows the ball while it's far away,
/// reads the bounce more and more as it gets closer, and fidgets while it waits. It reacts a moment late
/// and has a capped speed, so it can be beaten.
///
/// Skill slides how it plays each shot, decided once per incoming ball so it doesn't jitter. Low skill misreads
/// where the ball will land and meets it anywhere on the paddle; high skill reads it cleanly and takes it
/// off-center on purpose, angling the return away from the player's paddle.
nonisolated struct ComputerOpponent {
    var maxSpeed: CGFloat = Difficulty.standard.opponentSpeed
    var reactionDelay: TimeInterval = Difficulty.standard.reactionDelay
    /// Doesn't twitch for differences smaller than this.
    var deadZone: CGFloat = 0.02
    var skill: CGFloat = 1

    private var elapsed: TimeInterval = 0
    private static let swayAmount: CGFloat = 0.06
    private static let swaySpeed: Double = 1.8
    /// Extra wobble while it's still unsure where an incoming shot is going.
    private static let doubtWobble: CGFloat = 0.02
    private var sightings: [(time: TimeInterval, height: CGFloat)] = []
    /// Largest misreading of where the ball will land, at skill 0. Half of it is still there at contact.
    private static let misreadRange: CGFloat = 0.15
    /// Most it angles a return on purpose, as a share of the paddle's half-height.
    private static let maxAim: CGFloat = 0.6
    /// How far off-center a careless return can be taken at skill 0, as a share of the paddle's half-height.
    private static let carelessAim: CGFloat = 0.3
    /// This shot's plan: how far off it reads the landing spot, and where on the paddle it takes the ball.
    private var misread: CGFloat = 0
    private var aim: CGFloat = 0
    private var wasIncoming = false

    init(maxSpeed: CGFloat = Difficulty.standard.opponentSpeed,
         reactionDelay: TimeInterval = Difficulty.standard.reactionDelay,
         deadZone: CGFloat = 0.02,
         skill: CGFloat = 1) {
        self.maxSpeed = maxSpeed
        self.reactionDelay = reactionDelay
        self.deadZone = deadZone
        self.skill = skill
    }

    init(difficulty: Difficulty) {
        self.init(maxSpeed: difficulty.opponentSpeed, reactionDelay: difficulty.reactionDelay, skill: difficulty.skill)
    }

    mutating func nextPaddleY(
        current: CGFloat,
        ball: Ball,
        playerY: CGFloat,
        interval: TimeInterval,
        using generator: inout some RandomNumberGenerator
    ) -> CGFloat {
        elapsed += interval
        let incoming = ball.velocity.dx < 0
        if incoming, !wasIncoming { planShot(playerY: playerY, using: &generator) }
        wasIncoming = incoming
        sightings.append((elapsed, guess(for: ball)))
        // React to the newest sighting at least `reactionDelay` old, or the oldest one while none is that old.
        let cutoff = elapsed - reactionDelay
        let seenIndex = sightings.lastIndex { $0.time <= cutoff } ?? 0
        let seenHeight = sightings[seenIndex].height
        sightings.removeFirst(seenIndex)

        // While the ball heads away, sway gently around the middle instead of standing still.
        let idle = PongModel.courtSize.height / 2 + Self.swayAmount * CGFloat(sin(elapsed * Self.swaySpeed))
        // Taking the ball off-center angles the return: below center sends it down, above sends it up.
        let target = incoming ? seenHeight - aim * PongModel.paddleHeight / 2 : idle
        let distance = target - current
        let half = PongModel.paddleHeight / 2
        guard abs(distance) > deadZone else { return min(max(current, half), PongModel.courtSize.height - half) }
        let move = min(max(distance, -maxSpeed * interval), maxSpeed * interval)
        return min(max(current + move, half), PongModel.courtSize.height - half)
    }

    /// Where it thinks an incoming ball will arrive: where the ball is while it's far, where it will really
    /// land (bounces included) as it closes in, with a little wobble while it's still unsure.
    private func guess(for ball: Ball) -> CGFloat {
        let face = PongModel.paddleInset
        let distance = max(ball.position.x - face, 0)
        let certainty = min(max(1 - distance / (PongModel.courtSize.width - face), 0), 1)
        let arrival = PongModel.arrivalY(of: ball, atX: face)
        let wobble = Self.doubtWobble * (1 - certainty) * CGFloat(sin(elapsed * 5))
        let error = misread * (1 - certainty / 2)
        return ball.position.y + (arrival - ball.position.y) * certainty + wobble + error
    }

    /// Picks this shot's misreading and aim once, as the ball turns toward it.
    private mutating func planShot(playerY: CGFloat, using generator: inout some RandomNumberGenerator) {
        misread = CGFloat.random(in: -1...1, using: &generator) * Self.misreadRange * (1 - skill)
        // The further the player is from the middle, the harder it angles toward the other side.
        let middle = PongModel.courtSize.height / 2
        let openSide = min(max((middle - playerY) / 0.3, -1), 1)
        let careless = CGFloat.random(in: -1...1, using: &generator) * Self.carelessAim * (1 - skill)
        aim = openSide * Self.maxAim * skill + careless
    }
}

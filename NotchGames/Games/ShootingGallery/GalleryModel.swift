//
//  GalleryModel.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation

/// Shooting gallery rules in court units (1.6 × 1, y down). Each round sends 10 birds up from the ground in pairs;
/// each pair gets 3 shots and a few seconds before the birds escape off the top. Hit at least `quota` of the 10 to
/// go on to a faster round; fall short and the run is over.
nonisolated struct GalleryModel {
    static let courtSize = CGSize(width: 1.6, height: 1)
    static let birdsPerRound = 10
    static let birdsPerWave = 2
    static let shotsPerWave = 3
    /// Where birds take off and land; the ground line is drawn here.
    static let groundY: CGFloat = 0.9
    /// How close to a bird's center a shot must land.
    static let hitRadius: CGFloat = 0.065
    static let birdSize = CGSize(width: 0.09, height: 0.06)
    /// Pause between one pair leaving and the next taking off.
    static let waveGap: TimeInterval = 0.8
    static let fallAcceleration: CGFloat = 3
    static let perfectBonus = 1000

    private(set) var round = 1
    /// Hit (true) or missed (false) for each bird so far this round, in order.
    private(set) var results: [Bool] = []
    private(set) var birds: [GalleryBird] = []
    private(set) var shotsLeft = shotsPerWave
    private(set) var score = 0
    private(set) var isOver = false
    /// Set on the step a round was passed, so the game can show how it went before the next one.
    private(set) var passedRound: RoundSummary?
    private var waveTime: TimeInterval = 0
    private var untilNextWave: TimeInterval = 0.3

    /// Hits needed to pass this round: 6 of 10 at first, one more every two rounds, up to 9.
    var quota: Int { min(6 + (round - 1) / 2, 9) }
    var flightSpeed: CGFloat { min(0.45 + 0.08 * CGFloat(round - 1), 1.2) }
    /// Seconds a pair stays before escaping.
    var escapeAfter: TimeInterval { max(5 - 0.3 * Double(round - 1), 3) }
    var pointsPerBird: Int { 100 * round }
    var hits: Int { results.count(where: { $0 }) }

    mutating func step(by interval: TimeInterval, generator: inout some RandomNumberGenerator) {
        passedRound = nil
        guard !isOver else { return }
        guard !birds.isEmpty else {
            untilNextWave -= interval
            if untilNextWave <= 0 { launchWave(generator: &generator) }
            return
        }
        waveTime += interval
        let flying = birds.contains { $0.phase == .flying }
        if flying, waveTime >= escapeAfter || shotsLeft == 0 {
            for index in birds.indices where birds[index].phase == .flying {
                birds[index].phase = .escaping
                birds[index].velocity = CGVector(dx: 0, dy: -flightSpeed * 1.6)
            }
        }
        for index in birds.indices {
            Self.move(&birds[index], by: interval, speed: flightSpeed, generator: &generator)
        }
        // A bird is done once it lands (hit) or leaves the top (missed).
        for bird in birds {
            if bird.phase == .falling, bird.position.y >= Self.groundY {
                results.append(true)
            } else if bird.phase == .escaping, bird.position.y < -Self.birdSize.height {
                results.append(false)
            }
        }
        birds.removeAll {
            ($0.phase == .falling && $0.position.y >= Self.groundY)
                || ($0.phase == .escaping && $0.position.y < -Self.birdSize.height)
        }
        if birds.isEmpty { finishWave() }
    }

    /// A click at `point`. Uses a shot while a pair is flying; returns whether it hit.
    @discardableResult
    mutating func shoot(at point: CGPoint) -> Bool {
        guard !isOver, shotsLeft > 0, birds.contains(where: { $0.phase == .flying }) else { return false }
        shotsLeft -= 1
        let target = birds.indices
            .filter { birds[$0].phase == .flying }
            .map { ($0, hypot(birds[$0].position.x - point.x, birds[$0].position.y - point.y)) }
            .filter { $0.1 <= Self.hitRadius }
            .min { $0.1 < $1.1 }
        guard let (index, _) = target else { return false }
        birds[index].phase = .falling
        birds[index].velocity = CGVector(dx: 0, dy: 0.1)
        score += pointsPerBird
        return true
    }

    private static func move(
        _ bird: inout GalleryBird,
        by interval: TimeInterval,
        speed: CGFloat,
        generator: inout some RandomNumberGenerator
    ) {
        let seconds = CGFloat(interval)
        switch bird.phase {
        case .falling:
            bird.velocity.dy += Self.fallAcceleration * seconds
        case .escaping:
            break
        case .flying:
            bird.turnIn -= interval
            if bird.turnIn <= 0 {
                bird.velocity = heading(speed: speed, upward: bird.position.y > 0.6, generator: &generator)
                bird.turnIn = Double.random(in: 0.5...1.2, using: &generator)
            }
        }
        bird.position.x += bird.velocity.dx * seconds
        bird.position.y += bird.velocity.dy * seconds
        guard bird.phase == .flying else { return }
        // Flying birds bounce around inside the court, above the ground.
        let halfWidth = Self.birdSize.width / 2
        let halfHeight = Self.birdSize.height / 2
        if bird.position.x < halfWidth || bird.position.x > Self.courtSize.width - halfWidth {
            bird.velocity.dx = -bird.velocity.dx
            bird.position.x = min(max(bird.position.x, halfWidth), Self.courtSize.width - halfWidth)
        }
        let ceiling = halfHeight + 0.05
        let floor = Self.groundY - halfHeight - 0.05
        if bird.position.y < ceiling || bird.position.y > floor {
            bird.velocity.dy = -bird.velocity.dy
            bird.position.y = min(max(bird.position.y, ceiling), floor)
        }
    }

    private mutating func launchWave(generator: inout some RandomNumberGenerator) {
        waveTime = 0
        shotsLeft = Self.shotsPerWave
        birds = (0..<Self.birdsPerWave).map { _ in
            GalleryBird(
                position: CGPoint(x: CGFloat.random(in: 0.25...1.35, using: &generator), y: Self.groundY),
                velocity: Self.heading(speed: flightSpeed, upward: true, generator: &generator),
                turnIn: Double.random(in: 0.5...1.2, using: &generator)
            )
        }
    }

    private mutating func finishWave() {
        untilNextWave = Self.waveGap
        guard results.count >= Self.birdsPerRound else { return }
        guard hits >= quota else {
            isOver = true
            return
        }
        let bonus = hits == Self.birdsPerRound ? Self.perfectBonus * round : 0
        score += bonus
        let (passed, hitCount) = (round, hits)
        round += 1
        results = []
        passedRound = RoundSummary(round: passed, hits: hitCount, bonus: bonus, nextQuota: quota)
    }

    /// A random direction at `speed`, kept mostly sideways so birds cross the court; `upward` forces a climb.
    private static func heading(
        speed: CGFloat,
        upward: Bool,
        generator: inout some RandomNumberGenerator
    ) -> CGVector {
        let sideways = CGFloat.random(in: 0.4...0.9, using: &generator) * (Bool.random(using: &generator) ? 1 : -1)
        let climbs = upward || Bool.random(using: &generator)
        let vertical = CGFloat.random(in: 0.3...0.9, using: &generator) * (climbs ? -1 : 1)
        let length = hypot(sideways, vertical)
        return CGVector(dx: sideways / length * speed, dy: vertical / length * speed)
    }
}

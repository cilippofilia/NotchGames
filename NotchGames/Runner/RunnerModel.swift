//
//  RunnerModel.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation

/// Skate Run's rules in court units (1.6 wide like Pong's court, heights measured up from the ground):
/// the street scrolls left at a speed that creeps up, obstacles spawn off the right edge, and one hit ends the run.
/// Holding jump goes higher, ducking in the air drops faster, and ducking on the ground passes under pigeons.
nonisolated struct RunnerModel {
    static let courtWidth: CGFloat = 1.6
    /// One sprite pixel.
    static let pixel: CGFloat = 0.012
    /// The skater's left edge.
    static let skaterX: CGFloat = 0.2
    static let skaterPixels = (columns: 8, rows: 11)
    static let duckingPixels = 6
    /// Hit boxes are shrunk by this much on each side, so near misses feel fair.
    static let forgiveness: CGFloat = 0.012

    static let startSpeed: CGFloat = 0.6
    /// Court units per second, gained every second.
    static let acceleration: CGFloat = 0.012
    static let maxSpeed: CGFloat = 1.4
    static let gravity: CGFloat = 6
    /// Lighter gravity while jump is held, for up to `maxBoost` seconds after take-off.
    static let boostGravity: CGFloat = 2.5
    static let maxBoost: TimeInterval = 0.18
    /// Heavier gravity while ducking in the air.
    static let diveGravity: CGFloat = 14
    static let jumpSpeed: CGFloat = 1.5
    static let pointsPerUnit: CGFloat = 10
    static let coneGap: CGFloat = 0.02
    /// Speed at which cones can come in threes.
    static let tripleConeSpeed: CGFloat = 1.0
    /// Seconds of travel between obstacles, picked at random in this range (longer after a bench).
    static let gapSeconds: ClosedRange<Double> = 0.9...1.5
    static let benchGapFactor = 1.3

    private(set) var speed = startSpeed
    private(set) var distance: CGFloat = 0
    /// Height of the skater's feet above the ground.
    private(set) var altitude: CGFloat = 0
    private(set) var verticalSpeed: CGFloat = 0
    private(set) var isDucking = false
    private(set) var isOver = false
    var obstacles: [RunnerObstacle] = []
    /// Street left to travel before the next obstacle appears.
    private(set) var untilSpawn: CGFloat = startSpeed * 1.5
    private var boostTime: TimeInterval = 0

    var isAirborne: Bool { altitude > 0 || verticalSpeed > 0 }
    var score: Int { Int(distance * Self.pointsPerUnit) }

    var skaterBox: CGRect {
        let rows = isDucking ? Self.duckingPixels : Self.skaterPixels.rows
        return CGRect(
            x: Self.skaterX,
            y: altitude,
            width: CGFloat(Self.skaterPixels.columns) * Self.pixel,
            height: CGFloat(rows) * Self.pixel
        )
    }

    /// Advances the run. `jump` and `duck` are whether those keys are held.
    mutating func step(
        by interval: TimeInterval,
        jump: Bool,
        duck: Bool,
        generator: inout some RandomNumberGenerator
    ) {
        guard !isOver else { return }
        let seconds = CGFloat(interval)
        speed = min(speed + Self.acceleration * seconds, Self.maxSpeed)
        distance += speed * seconds
        moveSkater(by: interval, jump: jump, duck: duck)

        for index in obstacles.indices {
            obstacles[index].minX -= (speed + obstacles[index].kind.ownSpeed) * seconds
        }
        obstacles.removeAll { $0.minX + $0.width < -0.1 }
        untilSpawn -= speed * seconds
        if untilSpawn <= 0 { spawn(generator: &generator) }

        let skater = skaterBox.insetBy(dx: Self.forgiveness, dy: Self.forgiveness)
        let hit = obstacles.contains { $0.box.insetBy(dx: Self.forgiveness, dy: Self.forgiveness).intersects(skater) }
        if hit {
            isOver = true
        }
    }

    private mutating func moveSkater(by interval: TimeInterval, jump: Bool, duck: Bool) {
        let seconds = CGFloat(interval)
        if !isAirborne, jump, !duck {
            verticalSpeed = Self.jumpSpeed
            boostTime = 0
        }
        if isAirborne {
            let gravity: CGFloat
            if duck {
                gravity = Self.diveGravity
            } else if jump, boostTime < Self.maxBoost {
                gravity = Self.boostGravity
            } else {
                gravity = Self.gravity
            }
            boostTime += interval
            altitude += verticalSpeed * seconds - gravity * seconds * seconds / 2
            verticalSpeed -= gravity * seconds
            if altitude <= 0 {
                altitude = 0
                verticalSpeed = 0
            }
        }
        isDucking = duck && !isAirborne
    }

    /// Picks a kind allowed at this score, places it just past the right edge, and sets the gap to the next one.
    mutating func spawn(generator: inout some RandomNumberGenerator) {
        let allowed = RunnerObstacle.Kind.allCases.filter { $0.minScore <= score }
        let total = allowed.reduce(0) { $0 + $1.weight }
        var pick = Double.random(in: 0..<total, using: &generator)
        let kind = allowed.first { kind in
            pick -= kind.weight
            return pick < 0
        } ?? .cone
        let maxCones = speed >= Self.tripleConeSpeed ? 3 : 2
        let count = kind == .cone ? Int.random(in: 1...maxCones, using: &generator) : 1
        let obstacle = RunnerObstacle(kind: kind, minX: Self.courtWidth + 0.05 + min(untilSpawn, 0), count: count)
        obstacles.append(obstacle)
        let gap = Double.random(in: Self.gapSeconds, using: &generator) * (kind == .bench ? Self.benchGapFactor : 1)
        // A rolling cart covers ground faster, so leave room for how far it travels toward the skater.
        untilSpawn = obstacle.width + speed * CGFloat(gap) + kind.ownSpeed * CGFloat(gap)
    }
}

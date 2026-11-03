//
//  RunnerModelTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGames

struct RunnerModelTests {
    /// SplitMix64, so spawns are repeatable.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64 = 7
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var mixed = state
            mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
            mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
            return mixed ^ (mixed >> 31)
        }
    }

    private static let frame: TimeInterval = 1.0 / 60
    private var generator = SeededGenerator()

    /// Steps with no obstacles around, returning the highest altitude reached.
    @discardableResult
    private mutating func run(
        _ model: inout RunnerModel,
        for seconds: TimeInterval,
        jump: (Int) -> Bool = { _ in false },
        duck: Bool = false
    ) -> CGFloat {
        var peak: CGFloat = 0
        for index in 0..<Int(seconds / Self.frame) {
            model.obstacles = []
            model.step(by: Self.frame, jump: jump(index), duck: duck, generator: &generator)
            peak = max(peak, model.altitude)
        }
        return peak
    }

    @Test mutating func aTapJumpRisesAndLands() {
        var model = RunnerModel()
        let peak = run(&model, for: 1, jump: { $0 == 0 })
        #expect(peak > 0.1)
        #expect(model.altitude == 0)
        #expect(!model.isAirborne)
    }

    @Test mutating func holdingJumpGoesHigher() {
        var tapped = RunnerModel()
        var held = RunnerModel()
        let tapPeak = run(&tapped, for: 0.4, jump: { $0 == 0 })
        let heldPeak = run(&held, for: 0.4, jump: { $0 < 15 })
        #expect(heldPeak > tapPeak * 1.3)
    }

    @Test mutating func duckingInTheAirDropsFaster() {
        var floating = RunnerModel()
        var diving = RunnerModel()
        run(&floating, for: 0.15, jump: { $0 == 0 })
        run(&diving, for: 0.15, jump: { $0 == 0 })
        run(&floating, for: 0.1)
        run(&diving, for: 0.1, duck: true)
        #expect(diving.altitude < floating.altitude)
    }

    @Test mutating func aConeAheadEndsTheRun() {
        var model = RunnerModel()
        model.obstacles = [RunnerObstacle(kind: .cone, minX: RunnerModel.skaterX + 0.05, count: 1)]
        model.step(by: Self.frame, jump: false, duck: false, generator: &generator)
        #expect(model.isOver)
    }

    @Test mutating func duckingPassesUnderAPigeonAndStandingDoesNot() {
        let pigeon = RunnerObstacle(kind: .pigeon, minX: RunnerModel.skaterX + 0.02, count: 1)
        var ducking = RunnerModel()
        ducking.obstacles = [pigeon]
        ducking.step(by: Self.frame, jump: false, duck: true, generator: &generator)
        #expect(!ducking.isOver)

        var standing = RunnerModel()
        standing.obstacles = [pigeon]
        standing.step(by: Self.frame, jump: false, duck: false, generator: &generator)
        #expect(standing.isOver)
    }

    @Test mutating func speedAndScoreClimbToACap() {
        var model = RunnerModel()
        run(&model, for: 2)
        #expect(model.speed > RunnerModel.startSpeed)
        #expect(model.score > 0)
        run(&model, for: 90)
        #expect(model.speed == RunnerModel.maxSpeed)
    }

    @Test mutating func onlyConesAtTheStart() {
        var model = RunnerModel()
        for _ in 0..<50 {
            model.spawn(generator: &generator)
        }
        #expect(model.obstacles.allSatisfy { $0.kind == .cone })
        #expect(model.obstacles.allSatisfy { $0.count <= 2 })
    }
}

extension RunnerModelTests {
    /// Jumps (held for `holdFrames`) once the obstacle is `lead` away, then runs until it's well behind.
    private mutating func clears(_ kind: RunnerObstacle.Kind, holdFrames: Int, lead: CGFloat) -> Bool {
        var model = RunnerModel()
        let skaterFront = RunnerModel.skaterX + CGFloat(RunnerModel.skaterPixels.columns) * RunnerModel.pixel
        model.obstacles = [RunnerObstacle(kind: kind, minX: skaterFront + 0.5, count: 1)]
        var jumpFrame: Int?
        for frame in 0..<240 {
            guard let obstacle = model.obstacles.first(where: { $0.minX < RunnerModel.courtWidth }) else { break }
            if jumpFrame == nil, obstacle.minX - skaterFront <= lead { jumpFrame = frame }
            let jump = jumpFrame.map { frame - $0 < holdFrames } ?? false
            // Only the obstacle under test: drop anything newly spawned off the right edge.
            model.obstacles = model.obstacles.filter { $0.minX < RunnerModel.courtWidth }
            model.step(by: Self.frame, jump: jump, duck: false, generator: &generator)
            if model.isOver { return false }
        }
        return true
    }

    @Test mutating func aTapClearsAConeAndAHeldJumpClearsABench() {
        #expect(clears(.cone, holdFrames: 1, lead: 0.08))
        #expect(clears(.bench, holdFrames: 12, lead: 0.05))
        #expect(!clears(.bench, holdFrames: 0, lead: 0.05))
    }
}

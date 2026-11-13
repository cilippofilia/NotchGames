//
//  GalleryModelTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGames

struct GalleryModelTests {
    /// SplitMix64, so flight paths are repeatable.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64 = 11
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

    private mutating func run(_ model: inout GalleryModel, until done: (GalleryModel) -> Bool) {
        for _ in 0..<6000 where !done(model) {
            model.step(by: Self.frame, generator: &generator)
        }
    }

    /// Waits for the next pair, shoots `hits` of them dead on, then waits for the pair to finish.
    private mutating func playWave(_ model: inout GalleryModel, hits: Int) {
        run(&model) { !$0.birds.isEmpty }
        // Let them clear the ground first.
        for _ in 0..<20 { model.step(by: Self.frame, generator: &generator) }
        for _ in 0..<hits {
            guard let bird = model.birds.first(where: { $0.phase == .flying }) else { break }
            model.shoot(at: bird.position)
        }
        run(&model) { $0.birds.isEmpty }
    }

    @Test mutating func aPairTakesOffWithThreeShots() {
        var model = GalleryModel()
        run(&model) { !$0.birds.isEmpty }
        #expect(model.birds.count == GalleryModel.birdsPerWave)
        #expect(model.shotsLeft == GalleryModel.shotsPerWave)
        #expect(model.birds.allSatisfy { $0.phase == .flying })
    }

    @Test mutating func aShotOnABirdHitsAndAWideOneMisses() {
        var model = GalleryModel()
        run(&model) { !$0.birds.isEmpty }
        let target = model.birds[0].position
        let hit = model.shoot(at: target)
        #expect(hit)
        #expect(model.score == model.pointsPerBird)
        #expect(model.birds[0].phase == .falling)
        let wide = model.shoot(at: CGPoint(x: -1, y: -1))
        #expect(!wide)
        #expect(model.shotsLeft == GalleryModel.shotsPerWave - 2)
    }

    @Test mutating func clicksBetweenPairsDontUseShots() {
        var model = GalleryModel()
        let early = model.shoot(at: CGPoint(x: 0.8, y: 0.5))
        #expect(!early)
        #expect(model.shotsLeft == GalleryModel.shotsPerWave)
    }

    @Test mutating func unshotBirdsEscapeAndCountAsMisses() {
        var model = GalleryModel()
        playWave(&model, hits: 0)
        #expect(model.results == [false, false])
    }

    @Test mutating func runningOutOfShotsSendsThePairAway() {
        var model = GalleryModel()
        run(&model) { !$0.birds.isEmpty }
        for _ in 0..<GalleryModel.shotsPerWave { model.shoot(at: CGPoint(x: -1, y: -1)) }
        model.step(by: Self.frame, generator: &generator)
        #expect(model.birds.allSatisfy { $0.phase == .escaping })
    }

    @Test mutating func hitBirdsLandAndCountAsHits() {
        var model = GalleryModel()
        playWave(&model, hits: 2)
        #expect(model.results == [true, true])
    }

    @Test mutating func meetingTheQuotaStartsAFasterRound() {
        var model = GalleryModel()
        let firstSpeed = model.flightSpeed
        for hits in [2, 2, 2, 0, 0] { playWave(&model, hits: hits) }
        #expect(!model.isOver)
        #expect(model.passedRound == RoundSummary(round: 1, hits: 6, bonus: 0, nextQuota: 6))
        #expect(model.round == 2)
        #expect(model.results.isEmpty)
        #expect(model.flightSpeed > firstSpeed)
    }

    @Test mutating func fallingShortEndsTheRun() {
        var model = GalleryModel()
        for hits in [2, 2, 1, 0, 0] { playWave(&model, hits: hits) }
        #expect(model.isOver)
        #expect(model.round == 1)
    }

    @Test mutating func aPerfectRoundEarnsTheBonus() {
        var model = GalleryModel()
        for _ in 0..<5 { playWave(&model, hits: 2) }
        #expect(model.round == 2)
        #expect(model.score == 10 * 100 + GalleryModel.perfectBonus)
    }

    @Test mutating func newBirdsClimbOutOfTheGround() {
        var model = GalleryModel()
        run(&model) { !$0.birds.isEmpty }
        model.step(by: Self.frame, generator: &generator)
        for bird in model.birds {
            #expect(bird.velocity.dy < 0)
            // Risen one frame's flight from the ground, not snapped up to the flight floor.
            #expect(GalleryModel.groundY - bird.position.y < model.flightSpeed * 2 * Self.frame)
        }
    }

    @Test mutating func flyingBirdsStayInTheCourt() {
        var model = GalleryModel()
        run(&model) { !$0.birds.isEmpty }
        for _ in 0..<240 {
            model.step(by: Self.frame, generator: &generator)
            for bird in model.birds where bird.phase == .flying {
                #expect((0...GalleryModel.courtSize.width).contains(bird.position.x))
                #expect((0...GalleryModel.groundY).contains(bird.position.y))
            }
        }
    }
}

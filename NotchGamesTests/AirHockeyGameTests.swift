//
//  AirHockeyGameTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import NotchGames

struct AirHockeyGameTests {
    /// SplitMix64, so the computer's shot choices are repeatable.
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

    private static func match(puck: Ball, mallet: CGPoint, player: CGPoint) -> AirHockeyModel {
        var model = AirHockeyModel()
        model.puck = puck
        model.computerMallet = mallet
        model.playerMallet = player
        return model
    }

    @Test func computerDefendsItsGoalWhileThePuckIsAway() {
        var computer = AirHockeyOpponent()
        var generator = SeededGenerator()
        let puck = Ball(position: CGPoint(x: 1.2, y: 0.3), velocity: .zero)
        let match = Self.match(puck: puck, mallet: CGPoint(x: 0.3, y: 0.5), player: CGPoint(x: 1.3, y: 0.5))
        let target = computer.target(in: match,
                                            difficulty: .moderate, interval: Self.frame, using: &generator)
        #expect(computer.plan == .defend)
        #expect(target.x < 0.25)
        #expect(abs(target.y - (0.5 - AirHockeyModel.goalHalfHeight)) < 0.05)
    }

    @Test func computerGetsBehindAPuckItIsAheadOf() {
        var computer = AirHockeyOpponent()
        var generator = SeededGenerator()
        let puck = Ball(position: CGPoint(x: 0.5, y: 0.5), velocity: .zero)
        let match = Self.match(puck: puck, mallet: CGPoint(x: 0.7, y: 0.5), player: CGPoint(x: 1.3, y: 0.5))
        let target = computer.target(in: match,
                                            difficulty: .expert, interval: Self.frame, using: &generator)
        #expect(computer.plan == .lineUp)
        #expect(target.x < 0.5)
    }

    @Test func expertScoresFromTheServePastAStillPlayer() {
        var model = AirHockeyModel()
        model.puck = Ball(position: CGPoint(x: 0.4, y: 0.5), velocity: .zero)
        model.playerMallet = CGPoint(x: 1.5, y: 0.2)
        var computer = AirHockeyOpponent()
        var generator = SeededGenerator()
        for _ in 0..<(60 * 4) where model.computerScore == 0 {
            let target = computer.target(in: model, difficulty: .expert, interval: Self.frame, using: &generator)
            model.step(by: Self.frame, playerTarget: model.playerMallet, computerTarget: target,
                       computerSpeed: Difficulty.expert.opponentSpeed * 2.4)
        }
        #expect(model.computerScore == 1)
    }

    @Test func computerKeepsItsPlanWhileThePuckHoversAtTheMidline() {
        var computer = AirHockeyOpponent()
        var generator = SeededGenerator()
        for index in 0..<120 {
            let puck = Ball(position: CGPoint(x: index.isMultiple(of: 2) ? 0.79 : 0.81, y: 0.5), velocity: .zero)
            let match = Self.match(puck: puck, mallet: CGPoint(x: 0.2, y: 0.5), player: CGPoint(x: 1.3, y: 0.5))
            _ = computer.target(in: match,
                                                difficulty: .expert, interval: Self.frame, using: &generator)
            #expect(computer.plan == .defend)
        }
    }

    @Test func easyAimsAtThePlayerAndExpertAwayFromThem() {
        func averageMiss(_ difficulty: Difficulty) -> CGFloat {
            var generator = SeededGenerator()
            let player = CGPoint(x: 1.4, y: 0.35)
            var total: CGFloat = 0
            for _ in 0..<200 {
                var computer = AirHockeyOpponent()
                let puck = Ball(position: CGPoint(x: 0.4, y: 0.5), velocity: .zero)
                _ = computer.target(in: Self.match(puck: puck, mallet: CGPoint(x: 0.2, y: 0.5), player: player),
                                    difficulty: difficulty, interval: Self.frame, using: &generator)
                total += abs(computer.shotTarget.y - player.y)
            }
            return total / 200
        }
        // Only the ends are compared: easy's wide spread blurs the gap to moderate.
        #expect(averageMiss(.easy) < averageMiss(.expert))
    }

    @Test func skillRisesWithEachLevel() {
        let skills = Difficulty.allCases.map(\.skill)
        #expect(skills.first == 0)
        #expect(skills.last == 1)
        #expect(zip(skills, skills.dropFirst()).allSatisfy { $0 < $1 })
    }

    private func startedGame(_ model: AirHockeyModel = AirHockeyModel()) -> (AirHockeyGame, Date) {
        let game = AirHockeyGame(model: model)
        game.isPaused = false
        let now = Date.now
        game.tick(now: now)
        game.tick(now: now.addingTimeInterval(MatchClock.countdownLength + 0.1))
        return (game, now.addingTimeInterval(MatchClock.countdownLength + 0.1))
    }

    @Test func malletsHoldStillDuringTheCountdown() {
        let game = AirHockeyGame()
        game.isPaused = false
        let start = game.model.playerMallet
        let now = Date.now
        game.tick(now: now)
        game.aim(at: CGPoint(x: 1.0, y: 0.2))
        game.tick(now: now.addingTimeInterval(1))
        #expect(game.model.playerMallet == start)
    }

    @Test func playerMalletFollowsTheAimDuringPlay() {
        let (game, now) = startedGame()
        game.aim(at: CGPoint(x: 1.0, y: 0.2))
        game.tick(now: now.addingTimeInterval(1.0 / 30))
        #expect(game.model.playerMallet.y < 0.5)
    }

    @Test func goalRecordsThePointAndCountsDownAgain() {
        var model = AirHockeyModel()
        model.puck = Ball(position: CGPoint(x: 1.59, y: 0.5), velocity: CGVector(dx: 1, dy: 0))
        let (game, now) = startedGame(model)
        game.tick(now: now.addingTimeInterval(0.03))
        #expect(game.lastPoint?.side == .computer)
        #expect(game.countdown == MatchClock.countdownLength)
    }

    @Test func puckTrailKeepsOnlyRecentPositions() {
        let game = AirHockeyGame()
        game.isPaused = false
        let start = Date.now.addingTimeInterval(MatchClock.countdownLength + 0.1)
        game.tick(now: .now)
        for frame in 0..<30 {
            game.tick(now: start.addingTimeInterval(Double(frame) / 60))
        }
        #expect(!game.puckTrail.isEmpty)
        let newest = start.addingTimeInterval(29.0 / 60)
        #expect(game.puckTrail.allSatisfy { newest.timeIntervalSince($0.time) <= PongGame.trailLength })
    }
}

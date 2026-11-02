//
//  AirHockeyModelTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct AirHockeyModelTests {
    private typealias Model = AirHockeyModel

    /// Steps with both mallets holding still where they are.
    private func step(_ model: inout Model, by interval: Double = 0.02, playerTarget: CGPoint? = nil) {
        model.step(
            by: interval,
            playerTarget: playerTarget ?? model.playerMallet,
            computerTarget: model.computerMallet,
            computerSpeed: 1
        )
    }

    @Test func puckBouncesOffTheWallBesideTheGoal() {
        var model = Model()
        model.puck = Ball(position: CGPoint(x: 1.58, y: 0.1), velocity: CGVector(dx: 1, dy: 0))
        step(&model)
        #expect(model.puck.velocity.dx < 0)
        #expect(model.computerScore == 0)
        #expect(model.wallBounce?.inward.dx == -1)
    }

    @Test func puckInTheGoalScoresForTheOtherSide() {
        var model = Model()
        model.puck = Ball(position: CGPoint(x: 1.59, y: 0.5), velocity: CGVector(dx: 1, dy: 0))
        step(&model, by: 0.03)
        #expect(model.computerScore == 1)
        // The side that conceded gets the puck, sitting still in its half.
        #expect(model.puck.position.x > Model.courtSize.width / 2)
        #expect(model.puck.velocity == .zero)
    }

    @Test func malletShootsThePuck() {
        var model = Model()
        model.puck = Ball(position: CGPoint(x: 1.2, y: 0.5), velocity: .zero)
        model.playerMallet = CGPoint(x: 1.3, y: 0.5)
        step(&model, by: 0.03, playerTarget: CGPoint(x: 1.1, y: 0.5))
        #expect(model.puck.velocity.dx < 0)
    }

    @Test func malletsStayInTheirOwnHalf() {
        var model = Model()
        for _ in 0..<60 {
            model.step(
                by: 0.03,
                playerTarget: CGPoint(x: 0.2, y: 0.5),
                computerTarget: CGPoint(x: 1.5, y: 0.5),
                computerSpeed: 5
            )
        }
        #expect(model.playerMallet.x >= Model.courtSize.width / 2 + Model.malletRadius - 0.0001)
        #expect(model.computerMallet.x <= Model.courtSize.width / 2 - Model.malletRadius + 0.0001)
    }

    @Test func frictionSlowsAFreePuck() {
        var model = Model()
        model.puck = Ball(position: CGPoint(x: 0.8, y: 0.5), velocity: CGVector(dx: 0.3, dy: 0.2))
        for _ in 0..<30 { step(&model, by: 1.0 / 30) }
        #expect(hypot(model.puck.velocity.dx, model.puck.velocity.dy) < hypot(0.3, 0.2))
    }

    @Test func puckSpeedIsCapped() {
        var model = Model()
        model.puck = Ball(position: CGPoint(x: 0.8, y: 0.5), velocity: CGVector(dx: 9, dy: 0))
        step(&model, by: 0.001)
        #expect(hypot(model.puck.velocity.dx, model.puck.velocity.dy) <= Model.maxPuckSpeed + 0.0001)
    }

    @Test func fifthGoalWins() {
        var model = Model()
        for _ in 0..<5 {
            model.puck = Ball(position: CGPoint(x: 0.01, y: 0.5), velocity: CGVector(dx: -1, dy: 0))
            step(&model, by: 0.03)
        }
        #expect(model.winner == .player)
    }
}

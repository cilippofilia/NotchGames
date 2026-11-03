//
//  AirHockeyOpponent.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Where the computer's mallet heads: guarding its goal while the puck is away, and in its own half getting
/// behind the puck, then striking it toward the player's goal.
nonisolated enum AirHockeyOpponent {
    /// How far through the puck it aims, so the strike carries pace.
    private static let followThrough: CGFloat = 0.15
    /// How far off the puck's line it steps when going around it.
    private static let sidestep: CGFloat = 0.12

    static func target(puck: Ball, mallet: CGPoint) -> CGPoint {
        let court = AirHockeyModel.courtSize
        let reach = AirHockeyModel.malletRadius + AirHockeyModel.puckRadius
        let goalTop = court.height / 2 - AirHockeyModel.goalHalfHeight
        let goalBottom = court.height / 2 + AirHockeyModel.goalHalfHeight

        guard puck.position.x < court.width / 2 else {
            // Puck in the player's half: stand in front of the goal, lined up with it.
            return CGPoint(x: AirHockeyModel.malletRadius * 2.5, y: min(max(puck.position.y, goalTop), goalBottom))
        }
        guard mallet.x < puck.position.x - reach / 2 else {
            // In front of the puck: go around it rather than knock it into its own goal.
            let side: CGFloat = mallet.y >= puck.position.y ? 1 : -1
            return CGPoint(x: puck.position.x - reach - 0.04, y: puck.position.y + side * Self.sidestep)
        }
        let goal = CGPoint(x: court.width, y: court.height / 2)
        let toGoal = CGVector(dx: goal.x - puck.position.x, dy: goal.y - puck.position.y)
        let length = max(hypot(toGoal.dx, toGoal.dy), 0.0001)
        return CGPoint(
            x: puck.position.x + toGoal.dx / length * Self.followThrough,
            y: puck.position.y + toGoal.dy / length * Self.followThrough
        )
    }
}

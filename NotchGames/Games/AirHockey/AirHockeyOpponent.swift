//
//  AirHockeyOpponent.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// The computer's mallet. It follows one plan at a time (guard the goal, line up a shot, drive through it)
/// and holds each plan for a moment before changing, so it doesn't twitch between them.
///
/// Difficulty slides one skill value. Low skill sees the puck late and chases where it was, mostly shoots at
/// the player's mallet with a wide spread, and swings from a sloppy angle. High skill reads where the puck is
/// going, aims for the open side of the goal or banks off a wall, and lines up carefully before striking.
nonisolated struct AirHockeyOpponent {
    enum Plan: Equatable {
        case defend
        case lineUp
        case drive
    }

    private(set) var plan = Plan.defend
    /// Where the current shot is aimed, on the player's goal line. A y outside the court is a bank shot.
    /// Picked once per shot, so the aim doesn't wander frame to frame.
    private(set) var shotTarget = CGPoint(x: AirHockeyModel.courtSize.width, y: AirHockeyModel.courtSize.height / 2)
    /// Starts at the minimum hold so the first decision isn't delayed.
    private var heldFor = Self.minimumHold
    private var elapsed: TimeInterval = 0
    private var goingAround = false
    /// Which side of the puck it goes around (1 below, -1 above), kept for the whole detour.
    private var detourSide: CGFloat = 1
    private var sightings: [(time: TimeInterval, puck: Ball)] = []

    /// Shortest time a plan is kept before switching.
    private static let minimumHold: TimeInterval = 0.15
    /// How far past the midline the puck must be before it changes between attack and defense.
    private static let midlineMargin: CGFloat = 0.06
    /// A puck coming at its goal faster than this gets blocked rather than chased.
    private static let threatSpeed: CGFloat = 0.6
    /// How far through the puck it aims, so the strike carries pace.
    private static let followThrough: CGFloat = 0.15
    /// Space left between mallet and puck when lining up.
    private static let lineUpGap: CGFloat = 0.03
    /// How far off the puck's line it steps when going around it.
    private static let sidestep: CGFloat = 0.12
    /// Strikes anyway after lining up this long, so a puck it can't get behind doesn't stall it.
    private static let lineUpPatience: TimeInterval = 1
    /// How long a strike lasts before it lines up again.
    private static let driveLength: TimeInterval = 0.5
    /// Extra look-ahead a skilled player adds on top of catching up its reaction delay.
    private static let lookAhead: CGFloat = 0.12

    /// Where its mallet heads this frame, given the match as it stands.
    mutating func target(
        in model: AirHockeyModel,
        difficulty: Difficulty,
        interval: TimeInterval,
        using generator: inout some RandomNumberGenerator
    ) -> CGPoint {
        let player = model.playerMallet
        let skill = difficulty.skill
        elapsed += interval
        heldFor += interval
        let seen = read(model.puck, delay: difficulty.reactionDelay, skill: skill)
        let middle = AirHockeyModel.courtSize.width / 2
        let canSwitch = heldFor >= Self.minimumHold

        if canSwitch {
            switch plan {
            case .defend:
                if seen.position.x < middle - Self.midlineMargin, seen.velocity.dx > -Self.threatSpeed {
                    startShot(player: player, skill: skill, using: &generator)
                }
            case .lineUp, .drive:
                if seen.position.x > middle + Self.midlineMargin { switchTo(.defend) }
            }
        }

        switch plan {
        case .defend:
            return guardPoint(seen: seen, skill: skill)
        case .lineUp:
            return lineUpPoint(seen: seen.position, mallet: model.computerMallet, skill: skill, canSwitch: canSwitch)
        case .drive:
            if canSwitch, heldFor > Self.driveLength { startShot(player: player, skill: skill, using: &generator) }
            let direction = Self.direction(from: seen.position, to: shotTarget)
            return CGPoint(
                x: seen.position.x + direction.dx * Self.followThrough,
                y: seen.position.y + direction.dy * Self.followThrough
            )
        }
    }

    // MARK: - Private

    /// Behind the puck on the line of the shot, then switches to driving once lined up, blocked by a wall,
    /// or out of patience.
    private mutating func lineUpPoint(seen: CGPoint, mallet: CGPoint, skill: CGFloat, canSwitch: Bool) -> CGPoint {
        let direction = Self.direction(from: seen, to: shotTarget)
        if let detour = detour(seen: seen, mallet: mallet, direction: direction) {
            if canSwitch, heldFor > Self.lineUpPatience { switchTo(.drive) }
            return detour
        }
        let reach = AirHockeyModel.malletRadius + AirHockeyModel.puckRadius + Self.lineUpGap
        let wanted = CGPoint(x: seen.x - direction.dx * reach, y: seen.y - direction.dy * reach)
        let reachable = AirHockeyModel.clamped(wanted, for: .computer)
        // Novices commit from a sloppy angle; experts wait until they're behind the line of the shot.
        let tolerance = Self.blend(0.08, 0.015, skill: skill)
        let linedUp = hypot(mallet.x - reachable.x, mallet.y - reachable.y) < tolerance
        let blocked = hypot(wanted.x - reachable.x, wanted.y - reachable.y) > 0.02
        if canSwitch, linedUp || blocked || heldFor > Self.lineUpPatience { switchTo(.drive) }
        return reachable
    }

    /// The puck as it sees it: a reaction delay old, then projected ahead as far as its skill reads.
    private mutating func read(_ puck: Ball, delay: TimeInterval, skill: CGFloat) -> Ball {
        sightings.append((elapsed, puck))
        let cutoff = elapsed - delay
        let index = sightings.lastIndex { $0.time <= cutoff } ?? 0
        var seen = sightings[index].puck
        sightings.removeFirst(index)
        let lead = (CGFloat(delay) + Self.lookAhead) * skill
        let radius = AirHockeyModel.puckRadius
        let court = AirHockeyModel.courtSize
        seen.position = CGPoint(
            x: min(max(seen.position.x + seen.velocity.dx * lead, radius), court.width - radius),
            y: min(max(seen.position.y + seen.velocity.dy * lead, radius), court.height - radius)
        )
        return seen
    }

    /// In front of its goal: level with the puck on easy, where an incoming puck will arrive on expert.
    private func guardPoint(seen: Ball, skill: CGFloat) -> CGPoint {
        let guardX = AirHockeyModel.malletRadius * 2.5
        let middle = AirHockeyModel.courtSize.height / 2
        let heading = seen.velocity.dx < 0 ? PongModel.arrivalY(of: seen, atX: guardX) : seen.position.y
        let height = seen.position.y + (heading - seen.position.y) * skill
        let half = AirHockeyModel.goalHalfHeight
        return CGPoint(x: guardX, y: min(max(height, middle - half), middle + half))
    }

    /// A point beside the puck while the mallet is in front of it, so it doesn't knock it into its own goal.
    /// Separate thresholds to start and stop going around keep it from flickering at the edge.
    private mutating func detour(seen: CGPoint, mallet: CGPoint, direction: CGVector) -> CGPoint? {
        let reach = AirHockeyModel.malletRadius + AirHockeyModel.puckRadius
        let behind = (mallet.x - seen.x) * direction.dx + (mallet.y - seen.y) * direction.dy
        if goingAround {
            if behind < -reach * 0.8 { goingAround = false }
        } else if behind > -reach * 0.3 {
            goingAround = true
            detourSide = mallet.y >= seen.y ? 1 : -1
        }
        guard goingAround else { return nil }
        var side = detourSide
        let stepped = seen.y + side * Self.sidestep
        let radius = AirHockeyModel.malletRadius
        if stepped < radius || stepped > AirHockeyModel.courtSize.height - radius { side = -side }
        return CGPoint(x: seen.x - reach - 0.04, y: seen.y + side * Self.sidestep)
    }

    /// Picks the next shot. Easy mostly fires at the player's mallet; harder levels go for the side of the goal
    /// the player isn't covering, expert sometimes off a wall, and the spread narrows as skill rises.
    private mutating func startShot(
        player: CGPoint,
        skill: CGFloat,
        using generator: inout some RandomNumberGenerator
    ) {
        let court = AirHockeyModel.courtSize
        let middle = court.height / 2
        let openY = player.y < middle
            ? middle + AirHockeyModel.goalHalfHeight * 0.6
            : middle - AirHockeyModel.goalHalfHeight * 0.6
        let atPlayerChance = (1 - skill) * 0.8
        let bankChance = max(skill - 0.5, 0) * 0.6
        let roll = CGFloat.random(in: 0..<1, using: &generator)
        var aimY: CGFloat
        if roll < atPlayerChance {
            aimY = player.y
        } else if roll >= 1 - bankChance {
            // Mirror the open spot across the nearer wall: a single bounce lands it there.
            let radius = AirHockeyModel.puckRadius
            aimY = openY > middle ? 2 * (court.height - radius) - openY : 2 * radius - openY
        } else {
            aimY = openY
        }
        let spread = Self.blend(0.3, 0.03, skill: skill)
        aimY += CGFloat.random(in: -spread...spread, using: &generator)
        shotTarget = CGPoint(x: court.width, y: aimY)
        goingAround = false
        switchTo(.lineUp)
    }

    private mutating func switchTo(_ next: Plan) {
        plan = next
        heldFor = 0
    }

    private static func direction(from start: CGPoint, to end: CGPoint) -> CGVector {
        let length = max(hypot(end.x - start.x, end.y - start.y), 0.0001)
        return CGVector(dx: (end.x - start.x) / length, dy: (end.y - start.y) / length)
    }

    private static func blend(_ easy: CGFloat, _ expert: CGFloat, skill: CGFloat) -> CGFloat {
        easy + (expert - easy) * skill
    }
}

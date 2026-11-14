//
//  Difficulty.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// How good the computer is. Higher levels move faster and react sooner.
nonisolated enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case moderate
    case hard
    case expert

    static let standard = Difficulty.moderate
    /// Where each game's choice is saved in user defaults. Pong keeps the original key from when one difficulty
    /// covered both games.
    static func storageKey(for game: GameKind) -> String {
        game == .pong ? "difficulty" : "\(game.rawValue)Difficulty"
    }

    /// Air Hockey used to share Pong's difficulty. Give it its own copy once, so it starts where the player left it.
    static func copySharedChoice(in defaults: UserDefaults) {
        let airHockeyKey = storageKey(for: .airHockey)
        guard defaults.object(forKey: airHockeyKey) == nil,
              let shared = defaults.string(forKey: storageKey(for: .pong)) else { return }
        defaults.set(shared, forKey: airHockeyKey)
    }

    var id: Self { self }

    var title: String {
        switch self {
        case .easy: String(localized: "easy")
        case .moderate: String(localized: "moderate")
        case .hard: String(localized: "hard")
        case .expert: String(localized: "expert")
        }
    }

    /// Top paddle speed, in court heights per second.
    var opponentSpeed: CGFloat {
        switch self {
        case .easy: 0.4
        case .moderate: 0.55
        case .hard: 0.75
        case .expert: 1.0
        }
    }

    /// How cleverly the computer plays: 0 guesses and aims carelessly or at the player,
    /// 1 reads the ball and aims for the open side.
    var skill: CGFloat {
        switch self {
        case .easy: 0
        case .moderate: 0.35
        case .hard: 0.7
        case .expert: 1
        }
    }

    /// How old the computer's view of the ball is.
    var reactionDelay: TimeInterval {
        switch self {
        case .easy: 0.28
        case .moderate: 0.2
        case .hard: 0.12
        case .expert: 0.06
        }
    }
}

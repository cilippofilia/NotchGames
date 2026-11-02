//
//  Difficulty.swift
//  NotchPong
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
    /// Where the choice is saved in user defaults.
    static let storageKey = "difficulty"

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

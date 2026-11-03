//
//  GameKind.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation

/// Which game the panel plays.
/// Game names are lowercase, matching the in-game style.
nonisolated enum GameKind: String, CaseIterable, Identifiable {
    case pong
    case airHockey
    case brickBreaker

    static let standard = GameKind.pong
    /// Where the choice is saved in user defaults.
    static let storageKey = "game"

    var id: Self { self }

    var title: String {
        switch self {
        case .pong: String(localized: "pong")
        case .airHockey: String(localized: "air hockey")
        case .brickBreaker: String(localized: "brick breaker")
        }
    }
}

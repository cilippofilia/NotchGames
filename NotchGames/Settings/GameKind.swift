//
//  GameKind.swift
//  NotchGames
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
    case snake
    case runner

    static let standard = GameKind.pong
    /// Where the choice is saved in user defaults.
    static let storageKey = "game"

    var id: Self { self }

    /// The panel's shape and sizes. The court fills the panel, so its aspect is also the court's.
    var panelShape: PanelShape {
        switch self {
        case .pong, .airHockey, .snake, .runner: .wide
        case .brickBreaker: .tall
        }
    }

    var title: String {
        switch self {
        case .pong: String(localized: "pong")
        case .airHockey: String(localized: "air hockey")
        case .brickBreaker: String(localized: "brick breaker")
        case .snake: String(localized: "snake")
        case .runner: String(localized: "runner")
        }
    }
}

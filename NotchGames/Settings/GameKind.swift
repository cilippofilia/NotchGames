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
    case shootingGallery

    static let standard = GameKind.pong
    /// Where the choice is saved in user defaults.
    static let storageKey = "game"

    var id: Self { self }

    /// The game `step` places along the list, wrapping around at both ends; the title screen's arrows.
    func neighbor(_ step: Int) -> GameKind {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[((index + step) % all.count + all.count) % all.count]
    }

    /// The panel's shape and sizes. The court fills the panel, so its aspect is also the court's.
    var panelShape: PanelShape {
        switch self {
        case .pong, .airHockey, .snake, .runner, .shootingGallery: .wide
        case .brickBreaker: .tall
        }
    }

    /// Played against the computer, with a difficulty and a win/loss record; the rest chase a best score.
    var hasOpponent: Bool { self == .pong || self == .airHockey }

    /// The game's Settings tab icon.
    var symbolName: String {
        switch self {
        case .pong: "circle.and.line.horizontal"
        case .airHockey: "hockey.puck"
        case .brickBreaker: "square.grid.3x2"
        case .snake: "scribble.variable"
        case .runner: "figure.skateboarding"
        case .shootingGallery: "scope"
        }
    }

    var title: String {
        switch self {
        case .pong: String(localized: "pong")
        case .airHockey: String(localized: "air hockey")
        case .brickBreaker: String(localized: "brick breaker")
        case .snake: String(localized: "snake")
        case .runner: String(localized: "runner")
        case .shootingGallery: String(localized: "shooting gallery")
        }
    }
}

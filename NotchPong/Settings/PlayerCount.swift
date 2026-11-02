//
//  PlayerCount.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation

/// One player against the computer, or two people sharing the keyboard and pointer.
nonisolated enum PlayerCount: String, CaseIterable, Identifiable {
    case one
    case two

    static let standard = PlayerCount.one
    /// Where the choice is saved in user defaults.
    static let storageKey = "players"

    var id: Self { self }

    var title: String {
        switch self {
        case .one: String(localized: "1 player")
        case .two: String(localized: "2 players")
        }
    }
}

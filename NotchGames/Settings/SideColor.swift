//
//  SideColor.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// The neon colors a side can pick for its paddle, mallet and goal. Pink and teal stay out: they're the ball's
/// and the court's.
nonisolated enum SideColor: String, CaseIterable, Identifiable {
    case blue
    case amber
    case green
    case violet
    case red

    /// Where the player's and the computer's choices are saved in user defaults.
    static let playerStorageKey = "playerColor"
    static let computerStorageKey = "computerColor"
    static let playerStandard = SideColor.blue
    static let computerStandard = SideColor.amber

    var id: Self { self }

    var color: Color {
        switch self {
        case .blue: Color(red: 64 / 255, green: 156 / 255, blue: 255 / 255)
        case .amber: Color(red: 255 / 255, green: 159 / 255, blue: 28 / 255)
        case .green: Color(red: 57 / 255, green: 255 / 255, blue: 90 / 255)
        case .violet: Color(red: 168 / 255, green: 110 / 255, blue: 255 / 255)
        case .red: Color(red: 255 / 255, green: 70 / 255, blue: 60 / 255)
        }
    }

    var title: String {
        switch self {
        case .blue: String(localized: "blue")
        case .amber: String(localized: "amber")
        case .green: String(localized: "green")
        case .violet: String(localized: "violet")
        case .red: String(localized: "red")
        }
    }

    /// Picking the other side's color swaps the two, so both sides are never the same color.
    static func choosing(
        _ pick: SideColor,
        mine: SideColor,
        theirs: SideColor
    ) -> (mine: SideColor, theirs: SideColor) {
        (pick, pick == theirs ? mine : theirs)
    }
}

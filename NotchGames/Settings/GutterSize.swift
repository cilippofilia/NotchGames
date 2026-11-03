//
//  GutterSize.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// How far the pointer can stray outside the open panel before the game pauses.
nonisolated enum GutterSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    static let standard = GutterSize.medium
    static let largest = GutterSize.large
    /// Where the choice is saved in user defaults.
    static let storageKey = "gutter"

    /// The saved choice, for code outside SwiftUI views.
    static var saved: GutterSize {
        UserDefaults.standard.string(forKey: storageKey).flatMap(GutterSize.init(rawValue:)) ?? standard
    }

    var id: Self { self }

    var points: CGFloat {
        switch self {
        case .small: 40
        case .medium: 80
        case .large: 120
        }
    }

    var title: String {
        switch self {
        case .small: String(localized: "small")
        case .medium: String(localized: "medium")
        case .large: String(localized: "large")
        }
    }
}

//
//  PanelSize.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// The size "play" in the menu opens the panel to.
nonisolated enum PanelSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    /// Large matches how "play" behaved before this was a setting.
    static let standard = PanelSize.large
    /// Where the choice is saved in user defaults.
    static let storageKey = "panelSize"

    /// The saved choice, for code outside SwiftUI views.
    static var saved: PanelSize {
        UserDefaults.standard.string(forKey: storageKey).flatMap(PanelSize.init(rawValue:)) ?? standard
    }

    var id: Self { self }

    var bodyHeight: CGFloat {
        switch self {
        case .small: PullSizing.minBodyHeight
        case .medium: (PullSizing.minBodyHeight + PullSizing.maxBodyHeight) / 2
        case .large: PullSizing.maxBodyHeight
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

//
//  GalleryBackground.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// The scene behind the shooting gallery's ducks, picked in Settings.
nonisolated enum GalleryBackground: String, CaseIterable, Identifiable {
    case none
    case countryside
    case desert
    case city
    case seaside

    static let standard = GalleryBackground.countryside
    /// Where the choice is saved in user defaults.
    static let storageKey = "galleryBackground"

    var id: Self { self }

    var title: String {
        switch self {
        case .none: String(localized: "none")
        case .countryside: String(localized: "countryside")
        case .desert: String(localized: "desert")
        case .city: String(localized: "city at night")
        case .seaside: String(localized: "seaside")
        }
    }
}

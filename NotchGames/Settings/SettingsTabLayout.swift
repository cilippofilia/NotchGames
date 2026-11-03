//
//  SettingsTabLayout.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

extension View {
    /// Every Settings tab's form: grouped, draggable in width, and exactly as tall as its content, so the window
    /// resizes to each tab.
    func settingsTabLayout() -> some View {
        formStyle(.grouped)
            .frame(minWidth: 420, idealWidth: 480, maxWidth: 720)
            .fixedSize(horizontal: false, vertical: true)
    }
}

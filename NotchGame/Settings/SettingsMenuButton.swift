//
//  SettingsMenuButton.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// "Settings…" in the menu bar menu. The app has no Dock icon, so it activates itself first,
/// otherwise the window would open behind whatever app is in front.
struct SettingsMenuButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("settings…") {
            NSApplication.shared.activate()
            openSettings()
        }
        .keyboardShortcut(",")
    }
}

#Preview {
    SettingsMenuButton()
        .padding()
}

//
//  MatchControlsView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Restart and settings, offered while the game waits: paused or counting down.
struct MatchControlsView: View {
    let onRestart: () -> Void

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack {
            Button(
                "restart",
                systemImage: "arrow.counterclockwise",
                action: onRestart
            )
            .buttonStyle(.glassProminent)

            Button(
                "settings",
                systemImage: "gearshape"
            ) {
                // No Dock icon, so activate first or the window opens behind the front app.
                NSApplication.shared.activate()
                openSettings()
            }
            .buttonStyle(.glass)
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .tint(Palette.paddle.opacity(0.4))
    }
}

//
//  TitleView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/13/26.
//

import SwiftUI

/// The first thing a fresh install shows in the panel: the app's name, arrows to pick a game, settings and play.
struct TitleView: View {
    /// Saved once play is pressed, so the title screen only shows until the first game.
    static let seenKey = "hasSeenTitle"

    private static let name = "notchgames"
    private static let art = PixelArt.stack(
        PixelBug.rows,
        above: PixelArt.embolden(PixelFont.rows(for: name, spacing: 2)),
        gap: 4
    )

    @AppStorage(GameKind.storageKey) private var game = GameKind.standard
    @AppStorage(Self.seenKey) private var hasSeenTitle = false
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack {
            DotMatrixView(
                rows: Self.art,
                colors: ["#": Palette.neonText, "B": Palette.bug, "L": Palette.bug, "o": Palette.bugEyes]
            )
            .accessibilityElement()
            .accessibilityLabel(Self.name)

            HStack {
                Button("previous game", systemImage: "chevron.left") { game = game.neighbor(-1) }
                    .labelStyle(.iconOnly)
                    .keyboardShortcut(.leftArrow, modifiers: [])

                ZStack {
                    // The longest name reserves the width, so the arrows stay put while flipping through games.
                    ForEach(GameKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.symbolName).hidden()
                    }
                    Label(game.title, systemImage: game.symbolName)
                        .foregroundStyle(Palette.paddle)
                        .contentTransition(.numericText())
                }
                .font(.title3)

                Button("next game", systemImage: "chevron.right") { game = game.neighbor(1) }
                    .labelStyle(.iconOnly)
                    .keyboardShortcut(.rightArrow, modifiers: [])
            }
            .accessibilityElement(children: .contain)

            VStack {
                Button("settings", systemImage: "gearshape") {
                    // No Dock icon, so activate first or the window opens behind the front app.
                    NSApplication.shared.activate()
                    openSettings()
                }

                Button("play", systemImage: "play.fill") { hasSeenTitle = true }
                    .buttonStyle(.glassProminent)
                    .tint(Palette.paddle)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .padding()
        .animation(.snappy, value: game)
    }
}

#Preview {
    TitleView()
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

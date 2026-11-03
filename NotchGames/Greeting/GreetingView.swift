//
//  GreetingView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The neon bug above "hello there", shown in the middle of the panel.
struct GreetingView: View {
    private static let message = "hello there"
    private static let art = PixelArt.stack(
        PixelArt.scale(PixelBug.rows, by: 2),
        // Two columns between letters, so they stay apart once the strokes are thickened.
        above: PixelArt.embolden(PixelFont.rows(for: message, spacing: 2)),
        gap: 4
    )

    var body: some View {
        DotMatrixView(
            rows: Self.art,
            colors: ["#": Palette.neonText, "B": Palette.bug, "L": Palette.bug, "o": Palette.bugEyes]
        )
        .accessibilityElement()
        .accessibilityLabel(Self.message)
    }
}

#Preview {
    GreetingView()
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

//
//  ScoreLabel.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Whose score it is, smaller and dimmer than the number beside it.
struct ScoreLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .bold()
            .foregroundStyle(Palette.paddle.opacity(0.5))
    }
}

#Preview {
    ScoreLabel(text: "CPU")
        .padding()
        .background(Palette.background)
}

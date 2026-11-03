//
//  LivesView.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Small teal dots: filled for lives left, outlined for lives lost.
struct LivesView: View {
    let lives: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<BrickBreakerModel.startingLives, id: \.self) { index in
                Circle()
                    .strokeBorder(Palette.paddle.opacity(0.8), lineWidth: 1.5)
                    .background(Circle().fill(index < lives ? Palette.paddle.opacity(0.8) : .clear))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(lives) lives left")
    }
}

#Preview {
    LivesView(lives: 2)
        .padding()
        .background(Palette.background)
}

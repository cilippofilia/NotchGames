//
//  MatchScoreView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Both scores either side of the center line, each with its player's name, rolling to the new number on a point.
struct MatchScoreView: View {
    let computer: Int
    let player: Int
    let court: CGRect

    var body: some View {
        // Each side hugs the center line: "CPU 1 | 2 P1".
        HStack(spacing: court.width * 0.08) {
            HStack(alignment: .firstTextBaseline) {
                ScoreLabel(text: "CPU")
                ScoreNumber(value: computer)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            HStack(alignment: .firstTextBaseline) {
                ScoreNumber(value: player)
                ScoreLabel(text: "P1")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: court.width)
        .position(x: court.midX, y: court.minY + 14)
        .accessibilityHidden(true)
    }
}

#Preview {
    MatchScoreView(computer: 3, player: 5, court: CGRect(x: 24, y: 14, width: 432, height: 280))
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

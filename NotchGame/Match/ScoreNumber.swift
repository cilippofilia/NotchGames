//
//  ScoreNumber.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// One side's score, rolling to the new number when it changes.
struct ScoreNumber: View {
    let value: Int

    var body: some View {
        Text(value, format: .number)
            .font(.system(.title2, design: .monospaced))
            .bold()
            .foregroundStyle(Palette.paddle.opacity(0.8))
            .contentTransition(.numericText(value: Double(value)))
            .animation(.snappy, value: value)
    }
}

#Preview {
    ScoreNumber(value: 7)
        .padding()
        .background(Palette.background)
}

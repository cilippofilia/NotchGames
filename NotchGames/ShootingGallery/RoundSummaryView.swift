//
//  RoundSummaryView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Between rounds: how the last one went, what the next one needs, and a button to start it.
struct RoundSummaryView: View {
    let summary: RoundSummary
    let onContinue: () -> Void

    var body: some View {
        VStack {
            Text("round \(summary.round) clear")
                .font(.system(.title, design: .monospaced))
                .bold()
                .foregroundStyle(Palette.paddle)
            Text("\(summary.hits) of \(GalleryModel.birdsPerRound) hit")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(Palette.paddle.opacity(0.8))
            if summary.bonus > 0 {
                Text("perfect +\(summary.bonus)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(Palette.ball)
            }
            Text("next: hit \(summary.nextQuota) to pass")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(.secondary)
            Button("next round", action: onContinue)
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .padding()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    RoundSummaryView(summary: RoundSummary(round: 2, hits: 10, bonus: 2000, nextQuota: 7), onContinue: {})
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

//
//  GalleryHUDView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// The strip along the top: the round and its quota, a dot per bird (lit pink when hit, dim when missed),
/// the score and best, and the shots left for this pair.
struct GalleryHUDView: View {
    let display: GalleryDisplay

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HUDLabel(text: "round \(display.round)")
                HStack(spacing: 5) {
                    ForEach(0..<GalleryModel.birdsPerRound, id: \.self) { index in
                        BirdDot(result: display.results.indices.contains(index) ? display.results[index] : nil)
                    }
                }
                HUDLabel(text: "hit \(display.quota) to pass")
            }
            Spacer()
            HStack(alignment: .firstTextBaseline) {
                ScoreNumber(value: display.run.score)
                ScoreLabel(text: "best \(display.run.best)")
            }
            Spacer()
            VStack(alignment: .trailing) {
                HUDLabel(text: "shots")
                HStack(spacing: 5) {
                    ForEach(0..<GalleryModel.shotsPerWave, id: \.self) { index in
                        Capsule()
                            .fill(Palette.paddle.opacity(index < display.shotsLeft ? 0.8 : 0.15))
                            .frame(width: 6, height: 18)
                    }
                }
            }
        }
    }
}

/// The strip's labels: a step bigger than the score labels elsewhere, so they read at a glance mid-round.
private struct HUDLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.callout, design: .monospaced))
            .bold()
            .foregroundStyle(Palette.paddle.opacity(0.6))
    }
}

/// One bird of the round: lit when hit, dim when missed, an outline while still to come.
private struct BirdDot: View {
    let result: Bool?

    var body: some View {
        Circle()
            .fill(fill)
            .strokeBorder(Palette.ball.opacity(0.4), lineWidth: result == nil ? 1 : 0)
            .frame(width: 10, height: 10)
    }

    private var fill: Color {
        switch result {
        case true: Palette.ball
        case false: Palette.ball.opacity(0.15)
        case nil: .clear
        }
    }
}

#Preview {
    GalleryHUDView(display: GalleryDisplay(results: [true, false, true], shotsLeft: 2))
        .padding()
        .frame(width: 480)
        .background(Palette.background)
}

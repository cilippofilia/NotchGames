//
//  DotMatrixView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Draws pixel art as glowing rounded dots, like an LED sign. Characters without a color stay dark.
struct DotMatrixView: View {
    let rows: [String]
    let colors: [Character: Color]

    /// Empty dots kept around the art so the glow isn't clipped at the canvas edge.
    private static let glowMargin = 3

    var body: some View {
        let columns = rows.first?.count ?? 0
        let paddedColumns = CGFloat(columns + 2 * Self.glowMargin)
        let paddedRows = CGFloat(rows.count + 2 * Self.glowMargin)
        Canvas { context, size in
            guard columns > 0, !rows.isEmpty else { return }
            let dot = min(size.width / paddedColumns, size.height / paddedRows)
            let originX = (size.width - dot * CGFloat(columns)) / 2
            let originY = (size.height - dot * CGFloat(rows.count)) / 2
            // One path per color, so each color gets its own glow in a single pass.
            var paths: [Character: Path] = [:]
            for (rowIndex, row) in rows.enumerated() {
                for (columnIndex, character) in row.enumerated() where colors[character] != nil {
                    let cell = CGRect(
                        x: originX + CGFloat(columnIndex) * dot,
                        y: originY + CGFloat(rowIndex) * dot,
                        width: dot,
                        height: dot
                    ).insetBy(dx: dot * 0.1, dy: dot * 0.1)
                    paths[character, default: Path()].addRoundedRect(
                        in: cell,
                        cornerSize: CGSize(width: dot * 0.15, height: dot * 0.15)
                    )
                }
            }
            // Fixed order (by character) so details like the bug's eyes always draw over its body.
            for (character, path) in paths.sorted(by: { $0.key < $1.key }) {
                guard let color = colors[character] else { continue }
                context.drawLayer { layer in
                    layer.addFilter(.shadow(color: color.opacity(0.9), radius: dot * 1.2))
                    layer.addFilter(.shadow(color: color, radius: dot * 0.4))
                    layer.fill(path, with: .color(color))
                }
            }
        }
        .aspectRatio(paddedColumns / paddedRows, contentMode: .fit)
    }
}

#Preview {
    DotMatrixView(rows: PixelArt.embolden(PixelFont.rows(for: "3")), colors: ["#": Palette.ball])
        .frame(height: 120)
        .padding()
        .background(Palette.background)
}

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

    var body: some View {
        let columns = rows.first?.count ?? 0
        Canvas { context, size in
            guard columns > 0, !rows.isEmpty else { return }
            let dot = min(size.width / CGFloat(columns), size.height / CGFloat(rows.count))
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
        .aspectRatio(CGFloat(columns) / CGFloat(max(rows.count, 1)), contentMode: .fit)
    }
}

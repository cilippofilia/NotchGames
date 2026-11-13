//
//  GallerySprites.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// The shooting gallery's pixel art, as rows where `#` is lit and `.` is dark.
nonisolated enum GallerySprites {
    /// A bird facing right, wings up then down.
    static let bird = [
        [
            "..#......",
            "..##.....",
            "...##..##",
            ".#######.",
            "..#####..",
            "...#.#..."
        ],
        [
            ".........",
            ".......##",
            ".#######.",
            "..#####..",
            "..##.....",
            "..#......"
        ]
    ]

    /// One small square per lit pixel, stretched to fill `rect`.
    static func path(for rows: [String], in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width / CGFloat(rows.first?.count ?? 1)
        let height = rect.height / CGFloat(rows.count)
        for (row, line) in rows.enumerated() {
            for (column, character) in line.enumerated() where character != "." {
                path.addRect(CGRect(
                    x: rect.minX + CGFloat(column) * width,
                    y: rect.minY + CGFloat(row) * height,
                    width: width,
                    height: height
                ).insetBy(dx: width * 0.08, dy: height * 0.08))
            }
        }
        return path
    }
}

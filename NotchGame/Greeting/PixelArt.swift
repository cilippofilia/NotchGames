//
//  PixelArt.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

/// Helpers for pixel art stored as rows of characters, where `.` is an unlit dot.
nonisolated enum PixelArt {
    /// Makes every dot `factor` × `factor` dots.
    static func scale(_ rows: [String], by factor: Int) -> [String] {
        rows.flatMap { row in
            let wide = String(row.flatMap { repeatElement($0, count: factor) })
            return Array(repeating: wide, count: factor)
        }
    }

    /// Bold version: each lit dot also lights the dot to its right, so rows grow one column.
    static func embolden(_ rows: [String]) -> [String] {
        rows.map { row in
            let dots = Array(row) + ["."]
            return String(dots.indices.map { index in
                dots[index] != "." ? dots[index] : (index > 0 ? dots[index - 1] : ".")
            })
        }
    }

    /// Puts `top` above `bottom` with `gap` blank rows between, centering the narrower of the two.
    static func stack(_ top: [String], above bottom: [String], gap: Int) -> [String] {
        let width = max(top.first?.count ?? 0, bottom.first?.count ?? 0)
        func centered(_ row: String) -> String {
            let left = (width - row.count) / 2
            return String(repeating: ".", count: left) + row + String(repeating: ".", count: width - row.count - left)
        }
        let blank = Array(repeating: String(repeating: ".", count: width), count: gap)
        return top.map(centered) + blank + bottom.map(centered)
    }
}

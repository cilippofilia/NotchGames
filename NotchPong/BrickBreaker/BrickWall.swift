//
//  BrickWall.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics

/// The bricks, in court units. Row 0 is the top row; new rows arrive there and push the rest down.
nonisolated struct BrickWall: Equatable {
    static let columns = 10
    static let rowHeight: CGFloat = 0.045
    static let gap: CGFloat = 0.006
    /// Court y of the top row's top edge.
    static let top: CGFloat = 0.04

    /// `true` is a standing brick.
    private(set) var rows: [[Bool]]

    init(rows: Int) {
        self.rows = Array(repeating: Self.fullRow, count: rows)
    }

    mutating func dropRow() {
        rows.insert(Self.fullRow, at: 0)
    }

    mutating func breakBrick(row: Int, column: Int) {
        guard rows.indices.contains(row), rows[row].indices.contains(column) else { return }
        rows[row][column] = false
        // Emptied rows at the bottom hold nothing, so they go; the wall can't grow forever.
        while let last = rows.last, !last.contains(true) {
            rows.removeLast()
        }
    }

    func rect(row: Int, column: Int, courtWidth: CGFloat) -> CGRect {
        let width = (courtWidth - Self.gap * CGFloat(Self.columns + 1)) / CGFloat(Self.columns)
        return CGRect(
            x: Self.gap + CGFloat(column) * (width + Self.gap),
            y: Self.top + CGFloat(row) * (Self.rowHeight + Self.gap),
            width: width,
            height: Self.rowHeight
        )
    }

    /// Court y of the bottom edge of the lowest row with a brick left, or nil when the wall is empty.
    var lowestBrickBottom: CGFloat? {
        guard let row = rows.lastIndex(where: { $0.contains(true) }) else { return nil }
        return Self.top + CGFloat(row) * (Self.rowHeight + Self.gap) + Self.rowHeight
    }

    private static var fullRow: [Bool] { Array(repeating: true, count: columns) }
}

//
//  GridCell.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

/// One square of the snake's grid; column 0 is the left edge, row 0 the top.
nonisolated struct GridCell: Hashable {
    var column: Int
    var row: Int

    /// The next cell over in `direction`, which may lie off the grid.
    func moved(_ direction: HeldKeys.Direction) -> GridCell {
        switch direction {
        case .up: GridCell(column: column, row: row - 1)
        case .down: GridCell(column: column, row: row + 1)
        case .left: GridCell(column: column - 1, row: row)
        case .right: GridCell(column: column + 1, row: row)
        }
    }
}

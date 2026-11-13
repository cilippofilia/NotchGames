//
//  SnakeModel.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import Foundation

/// Snake rules on a grid as wide as Pong's court: the snake moves one cell per step, grows when it eats,
/// and the run ends when it runs into itself, or into the edge when walls are on (off, it wraps around).
nonisolated struct SnakeModel {
    static let columns = 32
    static let rows = 20
    static let startingLength = 3
    static let foodPoints = 10
    /// Seconds per step at the start, speeding up by `speedUpPerFood` for every food eaten, down to `fastestStep`.
    static let slowestStep: TimeInterval = 0.14
    static let speedUpPerFood: TimeInterval = 0.003
    static let fastestStep: TimeInterval = 0.06
    /// Quick taps are kept so a fast double turn isn't lost; more than this is mashing.
    private static let maxQueuedTurns = 2

    /// Head first.
    private(set) var body: [GridCell]
    private(set) var heading = HeldKeys.Direction.right
    private(set) var queuedTurns: [HeldKeys.Direction] = []
    var food: GridCell
    var hasWalls: Bool
    private(set) var score = 0
    private(set) var isOver = false
    /// Set once the snake has made its first move; before that, any direction is allowed, even backwards.
    private var hasMoved = false

    var head: GridCell { body[0] }
    var foodEaten: Int { body.count - Self.startingLength }
    var stepInterval: TimeInterval {
        max(Self.slowestStep - Double(foodEaten) * Self.speedUpPerFood, Self.fastestStep)
    }

    /// A fresh run: a short snake in the middle facing right, waiting for its first move.
    init(hasWalls: Bool = true, generator: inout some RandomNumberGenerator) {
        let middle = GridCell(column: Self.columns / 2, row: Self.rows / 2)
        let body = (0..<Self.startingLength).map { GridCell(column: middle.column - $0, row: middle.row) }
        let food = Self.freeCells(around: body).randomElement(using: &generator) ?? middle
        self.init(body: body, heading: .right, food: food, hasWalls: hasWalls, hasMoved: false)
    }

    /// A snake already on its way; used by tests to set up a position.
    init(body: [GridCell], heading: HeldKeys.Direction, food: GridCell, hasWalls: Bool, hasMoved: Bool = true) {
        self.body = body
        self.heading = heading
        self.food = food
        self.hasWalls = hasWalls
        self.hasMoved = hasMoved
    }

    init(hasWalls: Bool = true) {
        var generator = SystemRandomNumberGenerator()
        self.init(hasWalls: hasWalls, generator: &generator)
    }

    /// Queues a turn. Turns are checked against the last queued direction, so a quick up-then-left can't
    /// fold the snake back into itself. Before the first move, a backwards press turns the snake around.
    mutating func turn(_ direction: HeldKeys.Direction) {
        guard !isOver else { return }
        if !hasMoved, queuedTurns.isEmpty, direction == Self.opposite(of: heading) {
            body.reverse()
            heading = direction
            return
        }
        let last = queuedTurns.last ?? heading
        guard direction != last, direction != Self.opposite(of: last), queuedTurns.count < Self.maxQueuedTurns
        else { return }
        queuedTurns.append(direction)
    }

    /// Moves one cell.
    mutating func step(generator: inout some RandomNumberGenerator) {
        guard !isOver else { return }
        if !queuedTurns.isEmpty { heading = queuedTurns.removeFirst() }
        hasMoved = true

        var next = head.moved(heading)
        if !Self.isOnGrid(next) {
            if hasWalls {
                isOver = true
                return
            }
            next = GridCell(
                column: (next.column + Self.columns) % Self.columns,
                row: (next.row + Self.rows) % Self.rows
            )
        }
        let eats = next == food
        // The tail moves out of the way on the same step, unless the snake is growing.
        let blocking = eats ? body[...] : body.dropLast()
        if blocking.contains(next) {
            isOver = true
            return
        }
        body.insert(next, at: 0)
        if eats {
            score += Self.foodPoints
            guard let spot = Self.freeCells(around: body).randomElement(using: &generator) else {
                // The snake fills the grid: nowhere left to go.
                isOver = true
                return
            }
            food = spot
        } else {
            body.removeLast()
        }
    }

    static func opposite(of direction: HeldKeys.Direction) -> HeldKeys.Direction {
        switch direction {
        case .up: .down
        case .down: .up
        case .left: .right
        case .right: .left
        }
    }

    static func isOnGrid(_ cell: GridCell) -> Bool {
        (0..<columns).contains(cell.column) && (0..<rows).contains(cell.row)
    }

    /// Every cell the snake isn't on; picking from these never loops, however full the grid gets.
    private static func freeCells(around body: [GridCell]) -> [GridCell] {
        let taken = Set(body)
        return (0..<rows).flatMap { row in
            (0..<columns).map { GridCell(column: $0, row: row) }
        }
        .filter { !taken.contains($0) }
    }
}

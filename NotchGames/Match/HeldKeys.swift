//
//  HeldKeys.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// The direction keys held right now. Games move by these every frame, so a held key glides at a steady speed
/// instead of waiting on the system's key repeat (a jump, a pause, then a slow crawl).
nonisolated struct HeldKeys: Equatable {
    enum Direction: Hashable {
        // swiftlint:disable:next identifier_name
        case up, down, left, right
    }

    /// Court units per second while a key is held: crosses Pong's court height in about half a second.
    static let speed: CGFloat = 1.8

    private var pressed: Set<Direction> = []

    /// Unit-ish direction in court axes (y down); opposite keys cancel out.
    var vector: CGVector {
        CGVector(
            dx: (pressed.contains(.right) ? 1 : 0) - (pressed.contains(.left) ? 1 : 0),
            dy: (pressed.contains(.down) ? 1 : 0) - (pressed.contains(.up) ? 1 : 0)
        )
    }

    mutating func set(_ direction: Direction, isDown: Bool) {
        if isDown {
            pressed.insert(direction)
        } else {
            pressed.remove(direction)
        }
    }

    /// Records a key going down, repeating or up. True when it just went down, so a paused game can resume.
    mutating func record(_ press: KeyPress) -> Bool {
        guard let direction = Self.direction(key: press.key, characters: press.characters) else { return false }
        set(direction, isDown: press.phase != .up)
        return press.phase == .down
    }

    /// Key-ups go elsewhere once focus moves on, so forget everything rather than drift forever.
    mutating func releaseAll() {
        pressed = []
    }

    /// Arrows and W/A/S/D.
    static func direction(key: KeyEquivalent, characters: String) -> Direction? {
        switch (key, characters.lowercased()) {
        case (.upArrow, _), (_, "w"): .up
        case (.downArrow, _), (_, "s"): .down
        case (.leftArrow, _), (_, "a"): .left
        case (.rightArrow, _), (_, "d"): .right
        default: nil
        }
    }
}

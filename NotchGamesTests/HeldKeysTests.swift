//
//  HeldKeysTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/3/26.
//

import CoreGraphics
import SwiftUI
import Testing
@testable import NotchGames

struct HeldKeysTests {
    @Test func mapsArrowsAndWASD() {
        #expect(HeldKeys.direction(key: .upArrow, characters: "") == .up)
        #expect(HeldKeys.direction(key: "w", characters: "w") == .up)
        #expect(HeldKeys.direction(key: "S", characters: "S") == .down)
        #expect(HeldKeys.direction(key: .leftArrow, characters: "") == .left)
        #expect(HeldKeys.direction(key: "d", characters: "d") == .right)
        #expect(HeldKeys.direction(key: "x", characters: "x") == nil)
    }

    @Test func oppositeKeysCancelAndReleaseStops() {
        var keys = HeldKeys()
        keys.set(.left, isDown: true)
        #expect(keys.vector == CGVector(dx: -1, dy: 0))
        keys.set(.right, isDown: true)
        #expect(keys.vector == .zero)
        keys.set(.left, isDown: false)
        keys.set(.up, isDown: true)
        #expect(keys.vector == CGVector(dx: 1, dy: -1))
        keys.releaseAll()
        #expect(keys.vector == .zero)
    }
}

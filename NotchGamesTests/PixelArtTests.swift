//
//  PixelArtTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import Testing
@testable import NotchGames

struct PixelArtTests {
    @Test func titleUsesOnlyKnownGlyphs() {
        for character in "notchgames" {
            #expect(PixelFont.glyphs[character] != nil, "missing glyph for \(character)")
        }
    }

    @Test func textIsSevenRowsWithOneColumnBetweenLetters() {
        let rows = PixelFont.rows(for: "hi")
        #expect(rows.count == PixelFont.height)
        let expectedWidth = PixelFont.glyphs["h"]![0].count + 1 + PixelFont.glyphs["i"]![0].count
        #expect(rows.allSatisfy { $0.count == expectedWidth })
    }

    @Test func stackingCentersTheNarrowerPiece() {
        let stacked = PixelArt.stack(["#"], above: ["...."], gap: 1)
        #expect(stacked == [".#..", "....", "...."])
    }

    @Test func emboldenWidensEveryStrokeByOneDot() {
        #expect(PixelArt.embolden(["#..#.", ".#..."]) == ["##.##.", ".##..."])
    }

    @Test func boldTextKeepsLettersApart() {
        let rows = PixelArt.embolden(PixelFont.rows(for: "ll", spacing: 2))
        let gapColumn = PixelFont.glyphs["l"]![0].count + 1
        #expect(rows.allSatisfy { Array($0)[gapColumn] == "." })
    }
}

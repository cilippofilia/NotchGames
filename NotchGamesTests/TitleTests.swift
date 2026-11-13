//
//  TitleTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/13/26.
//

import CoreGraphics
import Testing
@testable import NotchGames

struct TitleTests {
    @Test func arrowsStepThroughTheGames() {
        #expect(GameKind.pong.neighbor(1) == .airHockey)
        #expect(GameKind.airHockey.neighbor(-1) == .pong)
    }

    @Test func arrowsWrapAroundAtBothEnds() {
        #expect(GameKind.pong.neighbor(-1) == .shootingGallery)
        #expect(GameKind.shootingGallery.neighbor(1) == .pong)
    }

    @Test func titleOpensAtOneSizeHoweverFarItIsPulled() {
        #expect(PanelShape.title.openHeight(for: 0) == PanelShape.title.openHeight(for: 1000))
    }

    @Test func everyLetterOfTheNameHasAGlyph() {
        for letter in "notchgames" {
            #expect(PixelFont.glyphs[letter] != nil, "missing glyph \(letter)")
        }
    }
}

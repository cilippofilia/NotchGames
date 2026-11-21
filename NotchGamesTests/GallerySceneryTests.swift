//
//  GallerySceneryTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI
import Testing
@testable import NotchGames

@MainActor
struct GallerySceneryTests {
    @Test func filledShapesGetAnOutlineAndAFill() throws {
        let layers = GalleryScenery.pixelate(.countryside, margin: 0)
        // The mountains are the one big shape: they must have both an outline and an inside.
        let mountains = try #require(layers.max { $0.fill.boundingRect.width < $1.fill.boundingRect.width })
        #expect(!mountains.edge.isEmpty)
        #expect(!mountains.fill.isEmpty)
    }

    @Test func noneDrawsNothing() {
        #expect(GalleryScenery.pixelate(.none, margin: 0).isEmpty)
    }

    @Test(arguments: GalleryBackground.allCases.filter { $0 != .none })
    func everySceneDrawsAboveTheGround(_ background: GalleryBackground) {
        let layers = GalleryScenery.pixelate(background, margin: 0.1)
        #expect(layers.contains { !$0.edge.isEmpty })
        for layer in layers {
            // A line pixel can straddle the ground.
            #expect(layer.edge.boundingRect.maxY <= GalleryModel.groundY + 0.01)
            #expect(layer.fill.isEmpty || layer.fill.boundingRect.maxY <= GalleryModel.groundY + 0.01)
        }
    }

    @Test func marginRunsTheSceneToThePanelEdges() {
        let width = { (margin: Double) in
            GalleryScenery.pixelate(.countryside, margin: margin).map(\.edge.boundingRect.width).max() ?? 0
        }
        #expect(width(0.2) > width(0) + 0.3)
    }
}

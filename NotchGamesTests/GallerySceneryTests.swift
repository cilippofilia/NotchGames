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
        let layers = GalleryScenery.pixelate(.countryside)
        // The mountains are the one big shape: they must have both an outline and an inside.
        let mountains = try #require(layers.max { $0.fill.boundingRect.width < $1.fill.boundingRect.width })
        #expect(!mountains.edge.isEmpty)
        #expect(!mountains.fill.isEmpty)
    }

    @Test func noneDrawsNothing() {
        #expect(GalleryScenery.pixelate(.none).isEmpty)
    }

    @Test(arguments: GalleryBackground.allCases.filter { $0 != .none })
    func everySceneDrawsAboveTheGround(_ background: GalleryBackground) {
        let layers = GalleryScenery.pixelate(background)
        #expect(layers.contains { !$0.edge.isEmpty })
        for layer in layers {
            // A line pixel can straddle the ground.
            #expect(layer.edge.boundingRect.maxY <= GalleryModel.groundY + 0.01)
            #expect(layer.fill.isEmpty || layer.fill.boundingRect.maxY <= GalleryModel.groundY + 0.01)
        }
    }

    @Test func sceneRunsPastTheCourtToThePanelEdges() {
        let edges = GalleryScenery.pixelate(.countryside).map(\.edge.boundingRect)
        // Real panels reach about 0.13 court units past each side of the court.
        #expect(edges.contains { $0.minX < -0.13 && $0.maxX > GalleryModel.courtSize.width + 0.13 })
    }
}

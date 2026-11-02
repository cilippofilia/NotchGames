//
//  PanelSizeTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct PanelSizeTests {
    @Test func sizesSpanTheAllowedRange() {
        #expect(PanelSize.small.bodyHeight == PullSizing.minBodyHeight)
        #expect(PanelSize.large.bodyHeight == PullSizing.maxBodyHeight)
        #expect(PanelSize.medium.bodyHeight > PanelSize.small.bodyHeight)
        #expect(PanelSize.medium.bodyHeight < PanelSize.large.bodyHeight)
    }

    @Test func largeIsTheDefaultLikeBefore() {
        #expect(PanelSize.standard == .large)
    }
}

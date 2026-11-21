//
//  SideColorTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/21/26.
//

import Testing
@testable import NotchGames

struct SideColorTests {
    @Test func pickingAFreeColorLeavesTheOtherSideAlone() {
        let result = SideColor.choosing(.green, mine: .blue, theirs: .amber)
        #expect(result.mine == .green)
        #expect(result.theirs == .amber)
    }

    @Test func pickingTheOtherSidesColorSwapsThem() {
        let result = SideColor.choosing(.amber, mine: .blue, theirs: .amber)
        #expect(result.mine == .amber)
        #expect(result.theirs == .blue)
    }
}

//
//  AttentionSignalTests.swift
//  NotchGamesTests
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation
import Testing
@testable import NotchGames

struct AttentionSignalTests {
    @Test func glowStartsAndEndsDark() {
        #expect(AttentionSignal.glow(at: 0) == 0)
        #expect(AttentionSignal.glow(at: AttentionSignal.duration) == 0)
    }

    @Test func glowIsFullMidPing() {
        #expect(AttentionSignal.glow(at: 2.5) == 1)
    }

    @Test func firstRippleStartsAtTheBorderAndTravelsOut() throws {
        #expect(AttentionSignal.rippleProgress(0, at: 0) == 0)
        let halfway = try #require(AttentionSignal.rippleProgress(0, at: AttentionSignal.rippleLength / 2))
        #expect(abs(halfway - 0.5) < 0.001)
    }

    @Test func rippleIsGoneOutsideItsLifetime() {
        #expect(AttentionSignal.rippleProgress(0, at: AttentionSignal.rippleLength) == nil)
        #expect(AttentionSignal.rippleProgress(1, at: 0) == nil)
    }

    @Test func eachBurstStartsARipple() {
        let burstGap = AttentionSignal.duration / 3
        for start in [0, burstGap, 2 * burstGap] {
            let fresh = (0..<AttentionSignal.rippleCount).contains {
                (AttentionSignal.rippleProgress($0, at: start + 0.01) ?? 1) < 0.05
            }
            #expect(fresh)
        }
    }

    @Test func noRippleOutlivesThePing() {
        for index in 0..<AttentionSignal.rippleCount {
            #expect(AttentionSignal.rippleProgress(index, at: AttentionSignal.duration) == nil)
        }
    }

    @Test(arguments: [
        ("notchgames://attention", true),
        ("NotchGames://attention", true),
        ("notchgames://Attention", true),
        ("notchgames://other", false),
        ("https://attention", false),
        ("notchgames:attention", false)
    ])
    func recognisesTheAttentionURL(url: String, expected: Bool) throws {
        #expect(AttentionSignal.isRequest(try #require(URL(string: url))) == expected)
    }
}

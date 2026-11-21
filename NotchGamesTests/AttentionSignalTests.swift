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

    @Test func shakesAtTheStartOfEachBurst() {
        let burstGap = AttentionSignal.duration / 3
        for start in [0, burstGap, 2 * burstGap] {
            #expect(abs(AttentionSignal.shake(at: start + 0.025)) > 2)
        }
    }

    @Test func restsBetweenBurstsAndAfterThePing() {
        #expect(AttentionSignal.shake(at: 1.0) == 0)
        #expect(AttentionSignal.shake(at: AttentionSignal.duration) == 0)
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

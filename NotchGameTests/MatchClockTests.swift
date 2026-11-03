//
//  MatchClockTests.swift
//  NotchGameTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation
import Testing
@testable import NotchGame

struct MatchClockTests {
    @Test func pausedClockDoesNothing() {
        var clock = MatchClock()
        #expect(clock.advance(to: .now) == .waiting)
    }

    @Test func resumingCountsDownBeforePlay() {
        var clock = MatchClock()
        clock.isPaused = false
        let now = Date.now
        #expect(clock.advance(to: now) == .waiting)
        #expect(clock.advance(to: now.addingTimeInterval(1)) == .countingDown)
        #expect(clock.countdown == MatchClock.countdownLength - 1)
    }

    @Test func countdownEndsThenPlayAdvancesInCappedSteps() {
        var clock = MatchClock()
        clock.isPaused = false
        let now = Date.now
        _ = clock.advance(to: now)
        #expect(clock.advance(to: now.addingTimeInterval(MatchClock.countdownLength)) == .countdownFinished)
        let step = clock.advance(to: now.addingTimeInterval(MatchClock.countdownLength + 1))
        #expect(step == .playing(MatchClock.maxStep))
    }

    @Test func pausingClearsTheClockSoResumeDoesNotJump() {
        var clock = MatchClock()
        clock.isPaused = false
        let now = Date.now
        _ = clock.advance(to: now)
        clock.isPaused = true
        clock.isPaused = false
        #expect(clock.advance(to: now.addingTimeInterval(10)) == .waiting)
        #expect(clock.countdown == MatchClock.countdownLength)
    }
}

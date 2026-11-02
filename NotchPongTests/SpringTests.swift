//
//  SpringTests.swift
//  NotchPongTests
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Testing
@testable import NotchPong

struct SpringTests {
    private func run(_ spring: inout Spring, seconds: Double, recordingMax maxValue: inout CGFloat) {
        for _ in 0..<Int(seconds * 60) {
            spring.step(by: 1.0 / 60)
            maxValue = max(maxValue, spring.value)
        }
    }

    @Test func springSettlesOnTarget() {
        var spring = Spring(stiffness: 260, dampingRatio: 0.55)
        spring.target = 100
        var peak: CGFloat = 0
        run(&spring, seconds: 3, recordingMax: &peak)
        #expect(spring.isSettled)
        #expect(abs(spring.value - 100) < 0.5)
    }

    @Test func bouncySpringOvershoots() {
        var spring = Spring(stiffness: 260, dampingRatio: 0.55)
        spring.target = 100
        var peak: CGFloat = 0
        run(&spring, seconds: 1, recordingMax: &peak)
        #expect(peak > 105)
    }

    @Test func largeTimeStepStaysStable() {
        var spring = Spring(stiffness: 900, dampingRatio: 0.9)
        spring.target = 400
        spring.step(by: 1)
        #expect(spring.value.isFinite)
        #expect(spring.value > 0 && spring.value < 500)
    }

    @Test func newSpringIsSettledAtZero() {
        #expect(Spring(stiffness: 260, dampingRatio: 0.55).isSettled)
    }
}

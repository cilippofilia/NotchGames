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
    @Test func startsOff() {
        #expect(!AttentionSignal().isOn)
    }

    @Test func pingTurnsItOn() {
        var signal = AttentionSignal()
        signal.ping()
        #expect(signal.isOn)
    }

    @Test func pointerAlreadyInsideKeepsItOn() {
        var signal = AttentionSignal()
        signal.ping()
        signal.pointer(isInside: true)
        signal.pointer(isInside: true)
        #expect(signal.isOn)
    }

    @Test func enteringAfterThePingClearsIt() {
        var signal = AttentionSignal()
        signal.ping()
        signal.pointer(isInside: false)
        signal.pointer(isInside: true)
        #expect(!signal.isOn)
    }

    @Test func leavingAndComingBackClearsIt() {
        var signal = AttentionSignal()
        signal.ping()
        signal.pointer(isInside: true)
        signal.pointer(isInside: false)
        signal.pointer(isInside: true)
        #expect(!signal.isOn)
    }

    @Test func stayingOutsideKeepsItOn() {
        var signal = AttentionSignal()
        signal.ping()
        signal.pointer(isInside: false)
        signal.pointer(isInside: false)
        #expect(signal.isOn)
    }

    @Test func secondPingWhileOnStaysOn() {
        var signal = AttentionSignal()
        signal.ping()
        signal.pointer(isInside: false)
        signal.ping()
        #expect(signal.isOn)
    }

    @Test(arguments: [
        ("notchgames://attention", true),
        ("NotchGames://attention", true),
        ("notchgames://other", false),
        ("https://attention", false),
        ("notchgames:attention", false),
    ])
    func recognisesTheAttentionURL(url: String, expected: Bool) throws {
        #expect(AttentionSignal.isRequest(try #require(URL(string: url))) == expected)
    }
}

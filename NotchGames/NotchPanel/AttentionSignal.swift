//
//  AttentionSignal.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import Foundation

/// An agent's "come back" ping (`open -g notchgames://attention`), held until the pointer moves onto the notch.
nonisolated struct AttentionSignal: Equatable {
    private(set) var isOn = false
    private var pointerWasInside = false

    /// Counts the pointer as already inside, so a pointer resting on the panel mid-game doesn't clear it straight away.
    mutating func ping() {
        isOn = true
        pointerWasInside = true
    }

    /// Clears the ping when the pointer arrives on the notch or panel.
    mutating func pointer(isInside: Bool) {
        if isInside, !pointerWasInside { isOn = false }
        pointerWasInside = isInside
    }

    static func isRequest(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "notchgames" && url.host() == "attention"
    }
}

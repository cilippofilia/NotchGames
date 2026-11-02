//
//  PanelState.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation
import Observation

/// Shared state between the panel controller (AppKit) and the panel's SwiftUI views.
@MainActor
@Observable
final class PanelState {
    var phase: PanelPhase = .closed
    var bodySize: CGSize = .zero
    var tear = TearPose(length: 0, offsetX: 0)
    /// How far the liquid currently hangs below the notch, and where the drip it grew from was.
    var hangingLength: CGFloat = 0
    var dropOffset: CGFloat = 0
    var notchWidth: CGFloat = 0
    /// Changes every time the panel opens, so the game knows to start a fresh match.
    private(set) var matchID = UUID()

    func startNewMatch() {
        matchID = UUID()
    }
}

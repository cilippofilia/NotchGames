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
    var neckWidth: CGFloat = 0
    var neckHeight: CGFloat = 0
    /// Changes every time the panel opens, so the game knows to start a fresh match.
    private(set) var matchID = UUID()

    func startNewMatch() {
        matchID = UUID()
    }
}

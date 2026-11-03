//
//  PanelState.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
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
    /// The current game's panel shape, set by `GameView`.
    var shape = GameKind.standard.panelShape
    /// False on Macs without a notch, where there's no notch to join.
    var hasNotch = false
    /// The pointer inside the open panel, in panel points from its top-left; nil when it's elsewhere.
    var panelPointer: CGPoint?
    /// While the Settings window is open the game stays paused, even with the pointer over the panel.
    var isSettingsOpen = false
}

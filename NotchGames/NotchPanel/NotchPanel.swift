//
//  NotchPanel.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import AppKit

/// Borderless, non-activating panel that floats above the menu bar.
final class NotchPanel: NSPanel {
    init(contentRect: CGRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        // Transient, not stationary: Mission Control hides it, so the drop can't hang over the Spaces bar.
        collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        // Always dark, so system colors like `.secondary` read on the black panel in light mode too.
        appearance = NSAppearance(named: .darkAqua)
    }

    /// Set while the game is open, so the panel only takes the keyboard when there's a game to play.
    var acceptsKeyboard = false

    // Lets the game take arrow keys without activating the app.
    override var canBecomeKey: Bool { acceptsKeyboard }
}

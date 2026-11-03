//
//  NotchGeometry.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import AppKit

/// Where the notch sits on a screen, in AppKit screen coordinates (origin bottom-left).
struct NotchGeometry: Equatable {
    let notchRect: CGRect
    let menuBarHeight: CGFloat

    /// Returns `nil` when the screen has no notch.
    static func make(
        screenFrame: CGRect,
        safeAreaTop: CGFloat,
        auxiliaryTopLeft: CGRect?,
        auxiliaryTopRight: CGRect?
    ) -> NotchGeometry? {
        guard safeAreaTop > 0, let left = auxiliaryTopLeft, let right = auxiliaryTopRight else { return nil }
        let rect = CGRect(
            x: left.maxX,
            y: screenFrame.maxY - safeAreaTop,
            width: right.minX - left.maxX,
            height: safeAreaTop
        )
        return NotchGeometry(notchRect: rect, menuBarHeight: safeAreaTop)
    }
}

extension NotchGeometry {
    static func forScreen(_ screen: NSScreen) -> NotchGeometry? {
        make(
            screenFrame: screen.frame,
            safeAreaTop: screen.safeAreaInsets.top,
            auxiliaryTopLeft: screen.auxiliaryTopLeftArea,
            auxiliaryTopRight: screen.auxiliaryTopRightArea
        )
    }
}

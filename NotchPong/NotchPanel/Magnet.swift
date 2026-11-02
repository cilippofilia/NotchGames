//
//  Magnet.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// The closer the pointer gets to the notch, the further the drop stretches toward it.
enum Magnet {
    static let radius: CGFloat = 180
    static let maxLength: CGFloat = 40
    static let maxLean: CGFloat = 24
    private static let leanFactor: CGFloat = 0.3

    /// Both points in screen coordinates (AppKit, y up).
    static func tear(pointer: CGPoint, notchBottomCenter: CGPoint) -> TearPose {
        let horizontal = pointer.x - notchBottomCenter.x
        let distance = hypot(horizontal, pointer.y - notchBottomCenter.y)
        let proximity = min(max(1 - distance / radius, 0), 1)
        guard proximity > 0 else { return TearPose(length: 0, offsetX: 0) }
        // Squared so the drop stays small until the pointer is really close.
        let length = maxLength * proximity * proximity
        let lean = min(max(horizontal * leanFactor * proximity, -maxLean), maxLean)
        return TearPose(length: length, offsetX: lean)
    }
}

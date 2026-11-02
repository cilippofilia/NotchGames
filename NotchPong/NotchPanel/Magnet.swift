//
//  Magnet.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// The drop hangs from the point on the notch's bottom edge closest to the pointer,
/// and stretches further the closer the pointer gets.
nonisolated enum Magnet {
    static let radius: CGFloat = 180
    static let maxLength: CGFloat = 40

    /// Points in screen coordinates (AppKit, y up). `maxShift` keeps the drop under the notch.
    static func tear(pointer: CGPoint, notchBottomCenter: CGPoint, maxShift: CGFloat) -> TearPose {
        let shift = min(max(pointer.x - notchBottomCenter.x, -maxShift), maxShift)
        let distance = hypot(pointer.x - (notchBottomCenter.x + shift), pointer.y - notchBottomCenter.y)
        let proximity = min(max(1 - distance / radius, 0), 1)
        guard proximity > 0 else { return TearPose(length: 0, offsetX: 0) }
        // Squared so the drop stays small until the pointer is really close.
        return TearPose(length: maxLength * proximity * proximity, offsetX: shift)
    }
}

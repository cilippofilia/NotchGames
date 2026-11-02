//
//  PanelPointer.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Where the pointer is relative to the open panel, for steering the paddle.
nonisolated enum PanelPointer {
    /// `location` and `panel` in screen coordinates (y up). `gutter` is the margin around the panel where the
    /// pointer still counts, so the game doesn't pause the moment it slips past the edge.
    /// Returns panel points from its top-left, or nil when the pointer is beyond the gutter.
    static func position(of location: CGPoint, in panel: CGRect, gutter: CGFloat) -> CGPoint? {
        guard panel.insetBy(dx: -gutter, dy: -gutter).contains(location) else { return nil }
        return CGPoint(x: location.x - panel.minX, y: panel.maxY - location.y)
    }
}

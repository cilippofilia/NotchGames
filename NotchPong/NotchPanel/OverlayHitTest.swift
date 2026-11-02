//
//  OverlayHitTest.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Decides when the transparent overlay catches mouse clicks instead of letting them through to the apps below.
nonisolated enum OverlayHitTest {
    /// Anywhere a press would start a pull must be caught, or the app underneath would get the same click.
    static func catchesClicks(at point: CGPoint, phase: PanelPhase, dropRect: CGRect, grabZone: CGRect?) -> Bool {
        phase == .dragging || dropRect.contains(point) || grabZone?.contains(point) == true
    }
}

//
//  CourtLayout.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Where the court sits inside the panel: clear of the rounded corners and of the close handle at the bottom.
nonisolated enum CourtLayout {
    private static let sideInset: CGFloat = 24
    private static let topInset: CGFloat = 20
    /// Leaves room for the close handle.
    private static let bottomInset: CGFloat = 28

    static func rect(in size: CGSize) -> CGRect {
        CGRect(
            x: sideInset,
            y: topInset,
            width: max(size.width - 2 * sideInset, 0),
            height: max(size.height - topInset - bottomInset, 0)
        )
    }

    /// Converts a pointer height in panel points to court units (0 top, 1 bottom).
    static func courtY(forPanelY panelY: CGFloat, in size: CGSize) -> CGFloat {
        let court = rect(in: size)
        guard court.height > 0 else { return 0.5 }
        return (panelY - court.minY) / court.height * PongModel.courtSize.height
    }
}

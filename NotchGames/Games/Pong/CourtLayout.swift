//
//  CourtLayout.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Where the court sits inside the panel: in from the sides for the rounded corners, close to the top and bottom.
nonisolated enum CourtLayout {
    private static let sideInset: CGFloat = 24
    /// For games whose ball should bounce right at the panel's sides, like the top and bottom.
    static let edgeInset: CGFloat = 6
    /// Thin top and bottom walls, so the ball bounces right at the panel's edge; the handle sits over the court.
    /// Measured from the panel's flat top edge, which sits below the neck curving out of the notch.
    private static let topInset: CGFloat = DropGeometry.neckRadius + 6
    private static let bottomInset: CGFloat = 6

    /// `sideInset` defaults to room for the rounded corners; `edgeInset` puts the walls at the panel's sides.
    static func rect(in size: CGSize, sideInset: CGFloat = sideInset) -> CGRect {
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

    /// Converts a pointer position in panel points to court units
    /// (x 0…`courtWidth` left to right, y 0…1 top to bottom).
    static func courtPoint(
        forPanelPoint point: CGPoint,
        in size: CGSize,
        courtWidth: CGFloat = PongModel.courtSize.width,
        sideInset: CGFloat = sideInset
    ) -> CGPoint {
        let court = rect(in: size, sideInset: sideInset)
        guard court.width > 0, court.height > 0 else { return CGPoint(x: courtWidth / 2, y: 0.5) }
        return CGPoint(
            x: (point.x - court.minX) / court.width * courtWidth,
            y: courtY(forPanelY: point.y, in: size)
        )
    }
}

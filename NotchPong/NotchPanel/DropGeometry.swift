//
//  DropGeometry.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// Size and position of the black drop hanging from the notch: a narrow drip that grows into the game panel.
nonisolated enum DropGeometry {
    static let dripWidth: CGFloat = 28
    /// The drip is wider where it clings to the notch than at its bulb, which makes it a tear.
    static let dripTopWidth: CGFloat = 44
    static let cornerRadius: CGFloat = 28
    /// Hanging length, past a full drip, over which the drip becomes the panel.
    private static let morphLength: CGFloat = 200

    /// Grows from the drip's width to the panel's full width at the maximum length.
    static func width(forLength length: CGFloat) -> CGFloat {
        let growth = (PullSizing.maxBodyHeight * PullSizing.aspect - dripWidth)
            / (PullSizing.maxBodyHeight - Magnet.maxLength)
        return dripWidth + max(length - Magnet.maxLength, 0) * growth
    }

    /// Width of the flat top edge against the notch: wider than the body for the drip, narrower for the panel,
    /// where the difference becomes its rounded top corners.
    static func topWidth(forLength length: CGFloat) -> CGFloat {
        let panelTop = max(width(forLength: length) - 2 * cornerRadius, 0)
        let amount = solidity(forLength: length)
        return dripTopWidth + (panelTop - dripTopWidth) * amount
    }

    /// Width the drop needs to be drawn in: its body, or its top edge while that is wider.
    static func frameWidth(forLength length: CGFloat) -> CGFloat {
        max(width(forLength: length), topWidth(forLength: length))
    }

    /// Starts under the pointer like the drip, then slides back to the notch's center.
    static func offset(forLength length: CGFloat, dropOffset: CGFloat) -> CGFloat {
        dropOffset * (1 - solidity(forLength: length))
    }

    /// 0 for a drip, 1 for the panel. Fades in the neon and the panel's contents.
    static func solidity(forLength length: CGFloat) -> CGFloat {
        min(max((length - Magnet.maxLength) / morphLength, 0), 1)
    }
}

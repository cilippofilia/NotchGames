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
    /// Hanging length, past a full drip, over which the top widens from the tear to the whole notch.
    private static let attachLength: CGFloat = 80
    static let cornerRadius: CGFloat = 28
    /// The small curve where a panel wider than the notch leaves it, keeping its top edge tight under the menu bar.
    static let neckRadius: CGFloat = 8
    /// Black drawn just above the notch's bottom edge, filling the menu bar showing under its rounded corners
    /// so the notch's sides seem to run straight down into the drop. The rest is hidden behind the notch.
    static let notchCapHeight: CGFloat = 12
    /// Hanging length, past a full drip, over which the drip becomes the panel.
    private static let morphLength: CGFloat = 200

    /// Grows from the drip's width to the panel's full width at the maximum length.
    static func width(forLength length: CGFloat) -> CGFloat {
        let growth = (PullSizing.maxBodyHeight * PullSizing.aspect - dripWidth)
            / (PullSizing.maxBodyHeight - Magnet.maxLength)
        return dripWidth + max(length - Magnet.maxLength, 0) * growth
    }

    /// Width of the top edge stuck to the notch: a narrow tear at rest, widening to the whole notch once pulled,
    /// so it looks like the notch itself is being stretched down. Centered on the body, and never past the notch.
    static func attachWidth(forLength length: CGFloat, notchWidth: CGFloat, dropOffset: CGFloat) -> CGFloat {
        let room = notchWidth - 2 * abs(offset(forLength: length, dropOffset: dropOffset))
        let progress = min(max((length - Magnet.maxLength) / attachLength, 0), 1)
        let wanted = dripTopWidth + (notchWidth - dripTopWidth) * progress
        return max(min(wanted, room), 0)
    }

    /// Width needed to draw the drop: its body, or its top edge while that is wider.
    static func frameWidth(forLength length: CGFloat, notchWidth: CGFloat, dropOffset: CGFloat) -> CGFloat {
        max(width(forLength: length), attachWidth(forLength: length, notchWidth: notchWidth, dropOffset: dropOffset))
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

//
//  ScorePulse.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics
import Foundation

/// The score that just changed pops up in size, then eases back.
nonisolated enum ScorePulse {
    static let duration: TimeInterval = 0.6
    static let peakScale: CGFloat = 1.5

    /// `age` is the time since the point; nil when there hasn't been one.
    static func scale(age: TimeInterval?) -> CGFloat {
        guard let age, age >= 0, age < duration else { return 1 }
        let remaining = CGFloat(1 - age / duration)
        return 1 + (peakScale - 1) * remaining * remaining
    }
}

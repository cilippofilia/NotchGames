//
//  TearPose.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

/// How the black drop under the notch looks right now.
nonisolated struct TearPose: Equatable {
    var length: CGFloat
    /// Horizontal lean of the drop's tip toward the pointer.
    var offsetX: CGFloat
}

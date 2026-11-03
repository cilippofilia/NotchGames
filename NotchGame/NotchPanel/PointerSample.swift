//
//  PointerSample.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import Foundation

/// One reading of the pointer, in screen coordinates (AppKit, y up).
struct PointerSample {
    let location: CGPoint
    let time: TimeInterval
    let isPressed: Bool
}

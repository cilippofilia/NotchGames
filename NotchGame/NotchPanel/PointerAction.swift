//
//  PointerAction.swift
//  NotchGame
//
//  Created by Filippo Cilia on 11/2/26.
//

import CoreGraphics

enum PointerAction: Equatable {
    case none
    case pull(CGFloat)
    case release(pull: CGFloat, upwardVelocity: CGFloat)
}

//
//  TearShape.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// A drop hanging from the top edge: wide where it meets the notch, ending in a round bulb.
nonisolated struct TearShape: Shape {
    static let topWidth: CGFloat = 44

    var pose: TearPose

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(pose.length, pose.offsetX) }
        set { pose = TearPose(length: newValue.first, offsetX: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard pose.length > 0.5 else { return path }
        let length = min(pose.length, rect.height)
        let bulbRadius = max(6, min(14, length * 0.35))
        let center = rect.midX + pose.offsetX
        let tip = CGPoint(x: center, y: length)

        path.move(to: CGPoint(x: center - Self.topWidth / 2, y: rect.minY))
        path.addCurve(
            to: tip,
            control1: CGPoint(x: center - Self.topWidth * 0.15, y: length * 0.35),
            control2: CGPoint(x: tip.x - bulbRadius * 1.8, y: length)
        )
        path.addCurve(
            to: CGPoint(x: center + Self.topWidth / 2, y: rect.minY),
            control1: CGPoint(x: tip.x + bulbRadius * 1.8, y: length),
            control2: CGPoint(x: center + Self.topWidth * 0.15, y: length * 0.35)
        )
        path.closeSubpath()
        return path
    }
}

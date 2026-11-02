//
//  NotchShape.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// A notch-width neck across the menu bar, opening into a wider body with rounded bottom corners.
nonisolated struct NotchShape: Shape {
    var neckWidth: CGFloat
    var neckHeight: CGFloat
    var bodyCornerRadius: CGFloat = 22

    func path(in rect: CGRect) -> Path {
        let neckLeft = rect.midX - min(neckWidth, rect.width) / 2
        let neckRight = rect.midX + min(neckWidth, rect.width) / 2
        let bodyTop = min(neckHeight, rect.maxY)
        let radius = max(0, min(bodyCornerRadius, (rect.maxY - bodyTop) / 2, rect.width / 2))

        var path = Path()
        path.move(to: CGPoint(x: neckLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: neckRight, y: rect.minY))
        path.addLine(to: CGPoint(x: neckRight, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.maxX, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            radius: radius
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX, y: rect.maxY - radius),
            radius: radius
        )
        path.addLine(to: CGPoint(x: rect.minX, y: bodyTop))
        path.addLine(to: CGPoint(x: neckLeft, y: bodyTop))
        path.closeSubpath()
        return path
    }
}

//
//  NotchShape.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// A notch-width neck that runs a little past the notch, then opens into a wider body.
/// Every corner, including the two inner curves where the neck meets the body, uses `cornerRadius`.
/// As an outline it traces only the body: from the flat top edge, down the sides and across the bottom.
nonisolated struct NotchShape: Shape {
    /// How far the neck extends below the notch before the body starts.
    static let neckSlack: CGFloat = 16

    var neckWidth: CGFloat
    /// Full neck length: menu bar height plus `neckSlack`.
    var neckHeight: CGFloat
    var cornerRadius: CGFloat = 16
    var isOutline = false

    func path(in rect: CGRect) -> Path {
        let neckLeft = rect.midX - min(neckWidth, rect.width) / 2
        let neckRight = rect.midX + min(neckWidth, rect.width) / 2
        let bodyTop = min(neckHeight, rect.maxY)
        // Each side of the body needs room for an inner and an outer curve.
        let sideRoom = (rect.width - (neckRight - neckLeft)) / 2
        let radius = max(0, min(cornerRadius, sideRoom / 2, (rect.maxY - bodyTop) / 2, bodyTop))

        var path = Path()
        if isOutline {
            path.move(to: CGPoint(x: neckRight + radius, y: bodyTop))
        } else {
            path.move(to: CGPoint(x: neckLeft, y: rect.minY))
            path.addLine(to: CGPoint(x: neckRight, y: rect.minY))
            path.addLine(to: CGPoint(x: neckRight, y: bodyTop - radius))
            path.addArc(
            tangent1End: CGPoint(x: neckRight, y: bodyTop),
                tangent2End: CGPoint(x: neckRight + radius, y: bodyTop),
                radius: radius
            )
        }
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: bodyTop),
            tangent2End: CGPoint(x: rect.maxX, y: rect.maxY),
            radius: radius
        )
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX, y: rect.maxY),
            radius: radius
        )
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX, y: bodyTop),
            radius: radius
        )
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: bodyTop),
            tangent2End: CGPoint(x: neckLeft, y: bodyTop),
            radius: radius
        )
        path.addLine(to: CGPoint(x: neckLeft - radius, y: bodyTop))
        if !isOutline {
            path.addArc(
            tangent1End: CGPoint(x: neckLeft, y: bodyTop),
                tangent2End: CGPoint(x: neckLeft, y: rect.minY),
                radius: radius
            )
            path.closeSubpath()
        }
        return path
    }
}

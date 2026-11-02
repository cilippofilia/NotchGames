//
//  DropShape.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The drop hanging from the notch. Its top edge sits flush against the notch; each side curves from there
/// to the body. A wider top makes the curves cling inward like a tear; a narrower top makes them rounded corners.
nonisolated struct DropShape: Shape {
    var length: CGFloat

    var animatableData: CGFloat {
        get { length }
        set { length = newValue }
    }

    /// Bezier handle length for a smooth, continuous-looking quarter turn.
    private static let handle: CGFloat = 0.55

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard length > 0.5 else { return path }
        let half = DropGeometry.width(forLength: length) / 2
        let topHalf = DropGeometry.topWidth(forLength: length) / 2
        let center = rect.midX
        let bottom = rect.minY + min(length, rect.height)
        let bottomRadius = min(DropGeometry.cornerRadius, half, (bottom - rect.minY) / 2)
        // A drip curves all the way down to its bulb; the panel only through its top corner.
        let solidity = DropGeometry.solidity(forLength: length)
        let sideSpan = bottom - bottomRadius - rect.minY
        let shoulderDepth = sideSpan * (1 - solidity) + DropGeometry.cornerRadius * solidity
        let shoulder = rect.minY + max(min(shoulderDepth, sideSpan), 0)

        let right = center + half
        let left = center - half
        path.move(to: CGPoint(x: center - topHalf, y: rect.minY))
        path.addLine(to: CGPoint(x: center + topHalf, y: rect.minY))
        turn(&path, to: CGPoint(x: right, y: shoulder), around: CGPoint(x: right, y: rect.minY))
        path.addLine(to: CGPoint(x: right, y: bottom - bottomRadius))
        turn(&path, to: CGPoint(x: right - bottomRadius, y: bottom), around: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: left + bottomRadius, y: bottom))
        turn(&path, to: CGPoint(x: left, y: bottom - bottomRadius), around: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: left, y: shoulder))
        turn(&path, to: CGPoint(x: center - topHalf, y: rect.minY), around: CGPoint(x: left, y: rect.minY))
        path.closeSubpath()
        return path
    }

    /// A smooth quarter turn from the current point to `end`, bending toward `corner`.
    /// Bulges outward when `corner` is outside the shape, clings inward when it's inside.
    private func turn(_ path: inout Path, to end: CGPoint, around corner: CGPoint) {
        guard let start = path.currentPoint else { return }
        func toward(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x + (corner.x - point.x) * Self.handle, y: point.y + (corner.y - point.y) * Self.handle)
        }
        path.addCurve(to: end, control1: toward(start), control2: toward(end))
    }
}

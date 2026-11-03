//
//  DropShape.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// The drop hanging from the notch, drawn so it looks like the notch itself is being pulled down.
///
/// Its top edge sticks to the notch. Where the body is narrower than that top, the side curves in from the notch
/// like stretched liquid. Where the body is wider, the side curves out of the notch into a flat edge, then rounds
/// over into the body.
nonisolated struct DropShape: Shape {
    var length: CGFloat
    var notchWidth: CGFloat
    var dropOffset: CGFloat
    /// The game's panel shape. Not animated: it only changes when the game does.
    var shape: PanelShape

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(length, dropOffset) }
        set {
            length = newValue.first
            dropOffset = newValue.second
        }
    }

    /// Bezier handle length for a smooth quarter turn.
    private static let handle: CGFloat = 0.55

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard length > 0.5 else { return path }
        let bodyHalf = DropGeometry.width(forLength: length, shape: shape) / 2
        let attachHalf = DropGeometry.attachWidth(forLength: length, notchWidth: notchWidth, dropOffset: dropOffset) / 2
        let attachCenter = rect.midX
        let top = rect.minY
        let bottom = top + min(length, rect.height)
        let bottomRadius = min(DropGeometry.cornerRadius, bodyHalf, length / 2)
        // How far down an inward curve reaches: all the way to the bulb for a drip, a short neck for the panel.
        let solidity = DropGeometry.solidity(forLength: length)
        let sideSpan = max(bottom - bottomRadius - top, 0)
        let inwardDepth = min(sideSpan * (1 - solidity) + DropGeometry.cornerRadius * solidity, sideSpan)

        let rightTop = CGPoint(x: attachCenter + attachHalf, y: top)
        let leftTop = CGPoint(x: attachCenter - attachHalf, y: top)
        let right = rect.midX + bodyHalf
        let left = rect.midX - bodyHalf

        path.move(to: leftTop)
        path.addLine(to: rightTop)
        let rightSide = side(from: rightTop, toBodyEdge: right, direction: 1, depth: inwardDepth, maxY: sideSpan)
        rightSide.forEach { turn(&path, to: $0.end, around: $0.corner) }
        path.addLine(to: CGPoint(x: right, y: bottom - bottomRadius))
        turn(&path, to: CGPoint(x: right - bottomRadius, y: bottom), around: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: left + bottomRadius, y: bottom))
        turn(&path, to: CGPoint(x: left, y: bottom - bottomRadius), around: CGPoint(x: left, y: bottom))
        // The left side is the mirror of the right, walked back up to the notch.
        let leftSide = side(from: leftTop, toBodyEdge: left, direction: -1, depth: inwardDepth, maxY: sideSpan)
        let leftPoints = [leftTop] + leftSide.map(\.end)
        for index in stride(from: leftSide.count - 1, through: 0, by: -1) {
            path.addLine(to: leftSide[index].end)
            turn(&path, to: leftPoints[index], around: leftSide[index].corner)
        }
        path.closeSubpath()
        return path
    }

    /// The turns that take one side from the notch down to the top of the body's straight edge.
    private func side(
        from attach: CGPoint,
        toBodyEdge edge: CGFloat,
        direction: CGFloat,
        depth: CGFloat,
        maxY: CGFloat
    ) -> [(end: CGPoint, corner: CGPoint)] {
        let outward = (edge - attach.x) * direction
        guard outward > 0.5 else {
            // Body tucked in under the notch: one inward curve, leaving the notch flat and meeting the body upright.
            return [(CGPoint(x: edge, y: attach.y + depth), CGPoint(x: edge, y: attach.y))]
        }
        // Body wider than the notch: curve out of the notch, along a flat edge, then round over into the body.
        let neck = min(DropGeometry.neckRadius, outward / 2, maxY / 2)
        let shoulder = min(DropGeometry.cornerRadius, outward - neck, maxY - neck)
        let flatY = attach.y + neck
        return [
            (CGPoint(x: attach.x + direction * neck, y: flatY), CGPoint(x: attach.x, y: flatY)),
            (CGPoint(x: edge - direction * shoulder, y: flatY), CGPoint(x: edge - direction * shoulder, y: flatY)),
            (CGPoint(x: edge, y: flatY + shoulder), CGPoint(x: edge, y: flatY))
        ]
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

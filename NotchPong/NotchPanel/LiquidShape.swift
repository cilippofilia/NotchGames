//
//  LiquidShape.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Draws a `LiquidProfile`: a drip that clings to the notch, or the full panel, and everything in between.
/// As an outline it traces only the body, from the flat top edge down the sides and across the bottom.
nonisolated struct LiquidShape: Shape {
    var length: CGFloat
    var dropOffset: CGFloat
    var notchWidth: CGFloat
    /// Height of the band above the notch's bottom edge to fill (the menu bar). 0 for the drip window.
    var neckHeight: CGFloat
    var isOutline = false

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(length, dropOffset) }
        set {
            length = newValue.first
            dropOffset = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard length > 0.5 else { return path }
        let profile = LiquidProfile.make(length: length, notchWidth: notchWidth, dropOffset: dropOffset)
        let top = neckHeight
        let bottom = min(top + length, rect.maxY)
        let shoulder = min(top + profile.transition, bottom)
        let center = rect.midX + profile.offsetX
        let attach = profile.attachHalfWidth
        let body = profile.bodyHalfWidth
        let radius = LiquidProfile.cornerRadius

        if isOutline {
            let flatStart = CGPoint(x: center + attach + min(radius, max(body - attach, 0)), y: shoulder)
            path.move(to: flatStart)
            appendRounded([
                (CGPoint(x: center + body, y: shoulder), radius),
                (CGPoint(x: center + body, y: bottom), radius),
                (CGPoint(x: center - body, y: bottom), radius),
                (CGPoint(x: center - body, y: shoulder), radius)
            ], from: flatStart, to: CGPoint(x: 2 * center - flatStart.x, y: shoulder), into: &path)
            return path
        }

        let start = CGPoint(x: center + attach + profile.flare, y: top)
        let end = CGPoint(x: center - attach - profile.flare, y: top)
        if neckHeight > 0 {
            path.move(to: CGPoint(x: rect.midX - notchWidth / 2, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + notchWidth / 2, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + notchWidth / 2, y: top))
            path.addLine(to: start)
        } else {
            path.move(to: start)
        }
        appendRounded([
            (CGPoint(x: center + attach, y: top), profile.flare),
            (CGPoint(x: center + attach, y: shoulder), radius),
            (CGPoint(x: center + body, y: shoulder), radius),
            (CGPoint(x: center + body, y: bottom), radius),
            (CGPoint(x: center - body, y: bottom), radius),
            (CGPoint(x: center - body, y: shoulder), radius),
            (CGPoint(x: center - attach, y: shoulder), radius),
            (CGPoint(x: center - attach, y: top), profile.flare)
        ], from: start, to: end, into: &path)
        if neckHeight > 0 { path.addLine(to: CGPoint(x: rect.midX - notchWidth / 2, y: top)) }
        path.closeSubpath()
        return path
    }

    /// Lines through `corners` to `end`, rounding each corner. Duplicate and straight-through points are skipped,
    /// and each radius shrinks to fit: half of a segment shared by two corners, all of one ending at `start`/`end`.
    private func appendRounded(
        _ corners: [(point: CGPoint, radius: CGFloat)],
        from start: CGPoint,
        to end: CGPoint,
        into path: inout Path
    ) {
        var kept: [(point: CGPoint, radius: CGFloat)] = []
        for corner in corners where distance(corner.point, kept.last?.point ?? start) > 0.5 {
            kept.append(corner)
        }
        kept.removeAll { distance($0.point, end) < 0.5 }

        var index = 0
        while index < kept.count {
            let previous = index == 0 ? start : kept[index - 1].point
            let next = index + 1 < kept.count ? kept[index + 1].point : end
            if isStraight(previous, kept[index].point, next) {
                kept.remove(at: index)
            } else {
                index += 1
            }
        }

        for (index, corner) in kept.enumerated() {
            let previous = index == 0 ? start : kept[index - 1].point
            let next = index + 1 < kept.count ? kept[index + 1].point : end
            let before = distance(previous, corner.point) / (index == 0 ? 1 : 2)
            let after = distance(corner.point, next) / (index + 1 < kept.count ? 2 : 1)
            let fitted = min(corner.radius, before, after)
            if fitted < 0.5 {
                path.addLine(to: corner.point)
            } else {
                path.addArc(tangent1End: corner.point, tangent2End: next, radius: fitted)
            }
        }
        path.addLine(to: end)
    }

    private func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(second.x - first.x, second.y - first.y)
    }

    private func isStraight(_ first: CGPoint, _ middle: CGPoint, _ last: CGPoint) -> Bool {
        let cross = (middle.x - first.x) * (last.y - middle.y) - (middle.y - first.y) * (last.x - middle.x)
        return abs(cross) < 0.01
    }
}

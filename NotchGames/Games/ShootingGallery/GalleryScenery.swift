//
//  GalleryScenery.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/21/26.
//

import SwiftUI

/// The scenery behind the ducks, one scene per `GalleryBackground`.
/// Pixel art on the ducks' own pixel grid, drawn faint and without glow so the birds stay the brightest thing.
enum GalleryScenery {
    /// One shape turned into pixels: a brighter outline round a faint fill, both in court units.
    struct Layer {
        var fill = Path()
        var edge = Path()
        let color: Color
        let fillOpacity: Double
    }

    /// The whole scene's strength; the birds and crosshair draw at full.
    private static let opacity = 0.35
    /// How much bigger than drawn the clouds, trees, bushes and fence are.
    private static let propScale = 1.3
    /// The same size as one pixel of a duck.
    private static let pixel = GalleryModel.birdSize.width / Double(GallerySprites.bird[0][0].count)

    /// How far past each side of the court the panel reaches, in court units (the court is centred).
    static func margin(in court: CGRect) -> Double {
        court.width > 0 ? court.minX / court.width * GalleryModel.courtSize.width : 0
    }

    /// A shape in court units, its color, and its fill strength (nil for a line, drawn all bright).
    private typealias Shape = (path: Path, color: Color, fill: Double?)

    /// Slow (a contains-check per pixel per shape), so the view does it once per panel size or pick, not per frame.
    static func pixelate(_ background: GalleryBackground, margin: Double) -> [Layer] {
        let shapes: [Shape] = switch background {
        case .none: []
        case .countryside: countryside(margin: margin)
        case .desert: desert(margin: margin)
        case .city: city(margin: margin)
        case .seaside: seaside(margin: margin)
        }
        // Lines are all edge; filled shapes light only their border pixels brightly.
        return shapes.map { pixelate($0.path, color: $0.color, fillOpacity: $0.fill) }
    }

    private static let thin = StrokeStyle(lineWidth: pixel)

    /// Props grow from where they stand, before stroking, so lines stay one pixel thick.
    private static func grown(_ path: Path, from across: Double, _ down: Double = ground) -> Path {
        path.applying(
            CGAffineTransform(translationX: across, y: down).scaledBy(x: propScale, y: propScale).translatedBy(x: -across, y: -down)
        )
    }

    // MARK: - Scenes

    /// Clouds, mountains, a river, trees, bushes, a fence and grass.
    private static func countryside(margin: Double) -> [Shape] {
        let leaf = Palette.neonText
        let wood = Palette.opponent
        var shapes: [Shape] = []
        for (across, down, size) in [(0.25, 0.22, 1.0), (0.85, 0.16, 0.8), (1.35, 0.28, 1.1)] {
            shapes.append((cloud(across: across, down: down, size: size * propScale), .white, 0.08))
        }
        shapes.append((mountains(margin: margin), Palette.player, 0.12))
        shapes.append((river, Palette.slowdown, 0.25))
        for across in [0.08, 0.22, 1.32, 1.47] { shapes.append((grown(pine(across: across), from: across), leaf, 0.15)) }
        for across in [0.38, 1.22] {
            shapes.append((grown(trunk(across: across), from: across).strokedPath(thin), wood, nil))
            let crown = Path(ellipseIn: CGRect(x: across - 0.045, y: 0.74, width: 0.09, height: 0.09))
            shapes.append((grown(crown, from: across), leaf, 0.15))
        }
        for across in [0.48, 1.08, 1.56] { shapes.append((grown(bush(across: across), from: across), leaf, 0.15)) }
        shapes.append((grown(fence(from: 0.82, to: 1.0), from: 0.91).strokedPath(thin), wood, nil))
        shapes.append((grass(margin: margin, skipping: riverMouth).strokedPath(thin), leaf, nil))
        return shapes
    }

    /// A low sun, flat-topped mesas, rolling dunes and cacti.
    private static func desert(margin: Double) -> [Shape] {
        var shapes: [Shape] = [
            (Path(ellipseIn: CGRect(x: 1.18, y: 0.18, width: 0.14, height: 0.14)), Palette.extraBall, 0.1),
            (cloud(across: 0.4, down: 0.2, size: 0.9 * propScale), .white, 0.06),
        ]
        for (left, top, right) in [(0.05, 0.6, 0.5), (0.92, 0.66, 1.28)] {
            var mesa = Path()
            mesa.addLines([
                CGPoint(x: left, y: ground), CGPoint(x: left + 0.07, y: top),
                CGPoint(x: right - 0.07, y: top), CGPoint(x: right, y: ground),
            ])
            mesa.closeSubpath()
            shapes.append((mesa, Palette.opponent, 0.12))
        }
        shapes.append((hills(margin: margin, low: 0.86, high: 0.8, wavelength: 0.4), Palette.extraBall, 0.12))
        for across in [0.3, 0.78, 1.42] { shapes.append((grown(cactus(across: across), from: across), Palette.neonText, 0.15)) }
        return shapes
    }

    /// A moon, stars, and a skyline with some windows lit.
    private static func city(margin: Double) -> [Shape] {
        var stars = Path()
        for (across, down) in [
            (0.08, 0.1), (0.52, 0.08), (0.7, 0.24), (0.95, 0.12), (1.12, 0.3),
            (1.3, 0.1), (1.52, 0.2), (0.18, 0.34), (0.62, 0.4), (1.45, 0.42),
        ] {
            stars.addRect(CGRect(x: across, y: down, width: pixel, height: pixel))
        }
        var buildings = Path()
        var windows = Path()
        let heights = [0.22, 0.32, 0.18, 0.4, 0.26, 0.15, 0.35, 0.24, 0.3, 0.2, 0.38, 0.17, 0.28]
        let width = 0.1
        for (index, left) in stride(from: -margin, to: 1.6 + margin, by: width + pixel).enumerated() {
            let top = ground - heights[index % heights.count]
            buildings.addRect(CGRect(x: left, y: top, width: width, height: ground - top))
            // Windows on a 3-pixel grid, about two in five lit, the same every time.
            for (row, down) in stride(from: top + 0.03, to: ground - 0.03, by: 0.04).enumerated() {
                for (column, across) in stride(from: left + 0.02, to: left + width - 0.02, by: 0.03).enumerated()
                where (index * 7 + row * 3 + column * 5) % 5 < 2 {
                    windows.addRect(CGRect(x: across, y: down, width: pixel, height: pixel))
                }
            }
        }
        return [
            (Path(ellipseIn: CGRect(x: 0.25, y: 0.14, width: 0.1, height: 0.1)), .white, 0.15),
            (stars, .white, nil),
            (buildings, Palette.player, 0.12),
            (windows, Palette.extraBall, nil),
        ]
    }

    /// A sun setting into the sea, a sailboat, beaches at both ends and palm trees.
    private static func seaside(margin: Double) -> [Shape] {
        let horizon = 0.72
        var sun = Path()
        sun.addLines((0...24).map { step in
            let angle = Double.pi + Double.pi * Double(step) / 24
            return CGPoint(x: 1.05 + 0.09 * cos(angle), y: horizon + 0.09 * sin(angle))
        })
        sun.closeSubpath()
        let sea = Path(CGRect(x: -margin, y: horizon, width: 1.6 + 2 * margin, height: ground - horizon))
        var waves = Path()
        for (row, down) in [0.76, 0.8, 0.84].enumerated() {
            for across in stride(from: -margin + Double(row) * 0.05, to: 1.6 + margin, by: 0.16) {
                waves.move(to: CGPoint(x: across, y: down))
                waves.addLine(to: CGPoint(x: across + 0.05, y: down))
            }
        }
        var hull = Path()
        hull.addLines([CGPoint(x: 0.36, y: 0.77), CGPoint(x: 0.54, y: 0.77), CGPoint(x: 0.5, y: 0.8), CGPoint(x: 0.4, y: 0.8)])
        hull.closeSubpath()
        var sail = Path()
        sail.addLines([CGPoint(x: 0.45, y: 0.6), CGPoint(x: 0.45, y: 0.76), CGPoint(x: 0.53, y: 0.76)])
        sail.closeSubpath()

        var shapes: [Shape] = [
            (cloud(across: 0.7, down: 0.2, size: propScale), .white, 0.08),
            (cloud(across: 1.4, down: 0.3, size: 0.8 * propScale), .white, 0.08),
            (sun, Palette.opponent, 0.15),
            (sea, Palette.slowdown, 0.15),
            (waves.strokedPath(thin), Palette.slowdown, nil),
            (hull, Palette.opponent, 0.2),
            (sail, .white, 0.1),
        ]
        for (start, end) in [(-margin, 0.32), (1.26, 1.6 + margin)] {
            var beach = Path()
            beach.move(to: CGPoint(x: start, y: ground))
            beach.addQuadCurve(to: CGPoint(x: end, y: ground), control: CGPoint(x: (start + end) / 2, y: 0.78))
            beach.closeSubpath()
            shapes.append((beach, Palette.extraBall, 0.15))
        }
        for (across, lean) in [(0.12, 0.04), (1.46, -0.04)] {
            shapes.append((grown(palmTrunk(across: across, lean: lean), from: across).strokedPath(thin), Palette.opponent, nil))
            shapes.append((grown(palmLeaves(across: across + lean), from: across).strokedPath(thin), Palette.neonText, nil))
        }
        return shapes
    }

    private static func pixelate(_ path: Path, color: Color, fillOpacity: Double?) -> Layer {
        var layer = Layer(color: color, fillOpacity: fillOpacity ?? 0)
        let bounds = path.boundingRect
        let firstColumn = Int((bounds.minX / pixel).rounded(.down))
        let firstRow = Int((bounds.minY / pixel).rounded(.down))
        let columns = Int((bounds.maxX / pixel).rounded(.up)) - firstColumn
        let rows = Int((bounds.maxY / pixel).rounded(.up)) - firstRow
        guard columns > 0, rows > 0 else { return layer }

        func inside(_ column: Int, _ row: Int) -> Bool {
            path.contains(CGPoint(x: (Double(column) + 0.5) * pixel, y: (Double(row) + 0.5) * pixel))
        }
        var lit = [[Bool]](repeating: [Bool](repeating: false, count: columns + 2), count: rows + 2)
        for row in 0..<rows {
            for column in 0..<columns {
                lit[row + 1][column + 1] = inside(firstColumn + column, firstRow + row)
            }
        }
        for row in 1...rows {
            for column in 1...columns where lit[row][column] {
                let isEdge = fillOpacity == nil
                    || !lit[row - 1][column] || !lit[row + 1][column] || !lit[row][column - 1] || !lit[row][column + 1]
                let square = CGRect(
                    x: Double(firstColumn + column - 1) * pixel,
                    y: Double(firstRow + row - 1) * pixel,
                    width: pixel,
                    height: pixel
                ).insetBy(dx: pixel * 0.08, dy: pixel * 0.08)
                if isEdge { layer.edge.addRect(square) } else { layer.fill.addRect(square) }
            }
        }
        return layer
    }

    static func draw(_ layers: [Layer], in court: CGRect, context: inout GraphicsContext) {
        let toPanel = CGAffineTransform(translationX: court.minX, y: court.minY)
            .scaledBy(x: court.width / GalleryModel.courtSize.width, y: court.height / GalleryModel.courtSize.height)
        var canvas = context
        canvas.opacity = opacity
        for layer in layers {
            canvas.fill(layer.fill.applying(toPanel), with: .color(layer.color.opacity(layer.fillOpacity)))
            canvas.fill(layer.edge.applying(toPanel), with: .color(layer.color.opacity(0.6)))
        }
    }

    private static let ground = GalleryModel.groundY
    /// Where the river meets the ground; grass skips it.
    private static let riverMouth = 0.55...0.76

    private static func cloud(across: Double, down: Double, size: Double) -> Path {
        var path = Path()
        for (dx, dy, base) in [(-0.06, 0.01, 0.03), (0.0, -0.01, 0.04), (0.06, 0.01, 0.03)] {
            let radius = base * size
            path.addEllipse(in: CGRect(x: across + dx * size - radius, y: down + dy * size - radius, width: radius * 2, height: radius * 2))
        }
        return path
    }

    private static func mountains(margin: Double) -> Path {
        let peaks: [(Double, Double)] = [
            // The valley at across 1.0 is where the river comes out.
            (0, 0.64), (0.35, 0.46), (0.7, 0.62), (0.82, 0.56), (1.0, 0.68), (1.28, 0.48), (1.6, 0.64),
        ]
        var path = Path()
        path.move(to: CGPoint(x: -margin, y: ground))
        path.addLine(to: CGPoint(x: -margin, y: peaks[0].1))
        for (across, down) in peaks { path.addLine(to: CGPoint(x: across, y: down)) }
        path.addLine(to: CGPoint(x: 1.6 + margin, y: peaks[peaks.count - 1].1))
        path.addLine(to: CGPoint(x: 1.6 + margin, y: ground))
        path.closeSubpath()
        return path
    }

    /// Winds out of the mountains and widens as it reaches the ground.
    private static var river: Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.97, y: 0.68))
        path.addQuadCurve(to: CGPoint(x: riverMouth.lowerBound, y: ground), control: CGPoint(x: 1.04, y: 0.82))
        path.addLine(to: CGPoint(x: riverMouth.upperBound, y: ground))
        path.addQuadCurve(to: CGPoint(x: 1.0, y: 0.68), control: CGPoint(x: 1.12, y: 0.84))
        path.closeSubpath()
        return path
    }

    private static func pine(across: Double) -> Path {
        var path = Path()
        for (top, base, half) in [(0.68, 0.82, 0.04), (0.74, 0.88, 0.05)] {
            path.move(to: CGPoint(x: across, y: top))
            path.addLine(to: CGPoint(x: across + half, y: base))
            path.addLine(to: CGPoint(x: across - half, y: base))
            path.closeSubpath()
        }
        path.addRect(CGRect(x: across - 0.006, y: 0.88, width: 0.012, height: ground - 0.88))
        return path
    }

    private static func trunk(across: Double) -> Path {
        Path { $0.move(to: CGPoint(x: across, y: 0.82)); $0.addLine(to: CGPoint(x: across, y: ground)) }
    }

    private static func bush(across: Double) -> Path {
        var path = Path()
        for (dx, base) in [(-0.025, 0.02), (0.0, 0.028), (0.025, 0.02)] {
            path.addEllipse(in: CGRect(x: across + dx - base, y: ground - base * 1.6, width: base * 2, height: base * 1.6))
        }
        return path
    }

    private static func fence(from start: Double, to end: Double) -> Path {
        var path = Path()
        for across in stride(from: start, through: end, by: 0.045) {
            path.move(to: CGPoint(x: across, y: ground))
            path.addLine(to: CGPoint(x: across, y: ground - 0.06))
        }
        for down in [ground - 0.045, ground - 0.02] {
            path.move(to: CGPoint(x: start, y: down))
            path.addLine(to: CGPoint(x: end, y: down))
        }
        return path
    }

    private static func grass(margin: Double, skipping gap: ClosedRange<Double>) -> Path {
        var path = Path()
        for across in stride(from: 0.03 - margin, to: 1.6 + margin, by: 0.06) where !gap.contains(across) {
            for lean in [-0.012, 0.0, 0.012] {
                path.move(to: CGPoint(x: across, y: ground))
                path.addLine(to: CGPoint(x: across + lean, y: ground - 0.025))
            }
        }
        return path
    }

    /// A wavy band of ground, peaking at `high` and dipping to `low`, running past both panel edges.
    private static func hills(margin: Double, low: Double, high: Double, wavelength: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: -margin, y: ground))
        path.addLine(to: CGPoint(x: -margin, y: low))
        var across = -margin
        var peak = true
        while across < 1.6 + margin {
            let next = across + wavelength / 2
            path.addQuadCurve(to: CGPoint(x: next, y: low), control: CGPoint(x: across + wavelength / 4, y: peak ? 2 * high - low : low))
            across = next
            peak.toggle()
        }
        path.addLine(to: CGPoint(x: across, y: ground))
        path.closeSubpath()
        return path
    }

    /// A saguaro: a trunk with one arm low on the left and one higher on the right.
    private static func cactus(across: Double) -> Path {
        var path = Path()
        path.addRect(CGRect(x: across - 0.012, y: 0.76, width: 0.024, height: ground - 0.76))
        path.addRect(CGRect(x: across - 0.045, y: 0.82, width: 0.035, height: 0.016))
        path.addRect(CGRect(x: across - 0.045, y: 0.78, width: 0.016, height: 0.056))
        path.addRect(CGRect(x: across + 0.01, y: 0.8, width: 0.03, height: 0.016))
        path.addRect(CGRect(x: across + 0.024, y: 0.77, width: 0.016, height: 0.046))
        return path
    }

    private static func palmTrunk(across: Double, lean: Double) -> Path {
        Path {
            $0.move(to: CGPoint(x: across, y: ground))
            $0.addQuadCurve(to: CGPoint(x: across + lean, y: 0.74), control: CGPoint(x: across, y: 0.8))
        }
    }

    /// Fronds drooping out from the top of the trunk.
    private static func palmLeaves(across: Double) -> Path {
        var path = Path()
        let top = CGPoint(x: across, y: 0.74)
        for (dx, dy) in [(-0.07, 0.04), (-0.05, -0.02), (0.05, -0.02), (0.07, 0.04)] {
            path.move(to: top)
            path.addQuadCurve(to: CGPoint(x: across + dx, y: top.y + dy), control: CGPoint(x: across + dx / 2, y: top.y - 0.04))
        }
        return path
    }
}

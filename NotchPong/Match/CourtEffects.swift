//
//  CourtEffects.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Drawing shared by every game's court: the center line, glows, wall sparks, point explosions and scores.
/// Positions are in court units (1.6 × 1.0), mapped into `court`, the court's rect in the canvas.
enum CourtEffects {
    /// Opacity of the ball or puck while the game waits (paused or counting down).
    static let waitingOpacity = 0.4

    static func drawCenterLine(in court: CGRect, context: inout GraphicsContext) {
        var centerLine = Path()
        centerLine.move(to: CGPoint(x: court.midX, y: court.minY))
        centerLine.addLine(to: CGPoint(x: court.midX, y: court.maxY))
        context.stroke(
            centerLine,
            with: .color(Palette.paddle.opacity(0.35)),
            style: StrokeStyle(lineWidth: 2, dash: [6, 8])
        )
    }

    /// The latest wall spark and point explosion.
    static func drawEvents(
        _ events: (wallHit: WallHit?, point: PointEvent?),
        at date: Date,
        in court: CGRect,
        context: inout GraphicsContext
    ) {
        let (wallHit, point) = events
        if let wallHit {
            drawWallSpark(for: wallHit, age: date.timeIntervalSince(wallHit.time), in: court, context: &context)
        }
        if let point {
            drawExplosion(for: point, age: date.timeIntervalSince(point.time), in: court, context: &context)
        }
    }

    /// A little teal spark where the ball or puck touched a wall.
    /// `courtWidth` is the game's court width in court units; Pong's by default.
    static func drawWallSpark(
        for hit: WallHit,
        age: TimeInterval,
        in court: CGRect,
        courtWidth: CGFloat = PongModel.courtSize.width,
        context: inout GraphicsContext
    ) {
        let particles = Explosion.spark(age: age, inward: hit.inward)
        guard let opacity = particles.first?.opacity else { return }
        let scaleX = court.width / courtWidth
        let scaleY = court.height / PongModel.courtSize.height
        let piece = max(court.height * 0.014, 3)
        var sparks = Path()
        for particle in particles {
            let center = CGPoint(
                x: court.minX + (hit.position.x + particle.offset.dx) * scaleX,
                y: court.minY + (hit.position.y + particle.offset.dy) * scaleY
            )
            sparks.addRect(CGRect(x: center.x - piece / 2, y: center.y - piece / 2, width: piece, height: piece))
        }
        glow(sparks, color: Palette.paddle.opacity(opacity), in: &context)
    }

    /// Pixels bursting back into the court from where the ball or puck went out.
    static func drawExplosion(
        for point: PointEvent,
        age: TimeInterval,
        in court: CGRect,
        context: inout GraphicsContext
    ) {
        let particles = Explosion.particles(age: age, side: point.side)
        guard let opacity = particles.first?.opacity else { return }
        let scaleX = court.width / PongModel.courtSize.width
        let scaleY = court.height / PongModel.courtSize.height
        let piece = max(court.height * 0.022, 4)
        var pink = Path()
        var teal = Path()
        for particle in particles {
            let center = CGPoint(
                x: court.minX + (point.position.x + particle.offset.dx) * scaleX,
                y: court.minY + (point.position.y + particle.offset.dy) * scaleY
            )
            let square = CGRect(x: center.x - piece / 2, y: center.y - piece / 2, width: piece, height: piece)
            if particle.isPink {
                pink.addRect(square)
            } else {
                teal.addRect(square)
            }
        }
        glow(pink, color: Palette.ball.opacity(opacity), in: &context)
        glow(teal, color: Palette.paddle.opacity(opacity), in: &context)
    }

    /// Computer's score on the left, the player's on the right; the one that just changed pops up briefly.
    /// Fading, shrinking copies of the ball along its recent path, oldest first, in view points.
    static func drawTrail(_ centers: [CGPoint], radius: CGFloat, in context: inout GraphicsContext) {
        for (index, center) in centers.enumerated() {
            let age = CGFloat(index + 1) / CGFloat(centers.count + 1)
            let size = radius * (0.4 + 0.6 * age)
            let bounds = CGRect(x: center.x - size, y: center.y - size, width: size * 2, height: size * 2)
            context.fill(Path(ellipseIn: bounds), with: .color(Palette.ball.opacity(0.35 * age)))
        }
    }

    static func glow(_ path: Path, color: Color, in context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: color, radius: 8))
            layer.addFilter(.shadow(color: color, radius: 2))
            layer.fill(path, with: .color(color))
        }
    }
}

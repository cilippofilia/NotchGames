//
//  PongView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Draws the match in neon and feeds it input: the pointer's height moves the right paddle, arrows or W/S too.
/// The game pauses whenever the pointer leaves the panel.
struct PongView: View {
    let state: PanelState

    @State private var game = PongGame()
    @AppStorage(Difficulty.storageKey) private var difficulty = Difficulty.standard
    @State private var size = CGSize.zero
    @FocusState private var isFocused: Bool

    private static let keyStep: CGFloat = 0.06
    private static let waitingBallOpacity = 0.4

    var body: some View {
        TimelineView(.animation(paused: game.isPaused)) { timeline in
            Canvas { context, canvasSize in
                Self.draw(game, at: timeline.date, in: &context, size: canvasSize)
            }
            .onChange(of: timeline.date) { _, date in
                game.tick(now: date)
            }
        }
        .overlay {
            PongCountdownView(game: game, panelHeight: size.height)
        }
        .overlay {
            PongMessageView(game: game)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: state.panelPointer) { _, pointer in
            follow(pointer)
        }
        .onChange(of: state.matchID) {
            game.reset()
        }
        .onChange(of: difficulty, initial: true) {
            game.difficulty = difficulty
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(keys: [.upArrow, .downArrow, "w", "s"]) { press in
            let isUp = press.key == .upArrow || press.characters == "w"
            game.nudgePlayerPaddle(by: isUp ? -Self.keyStep : Self.keyStep)
            if game.model.winner == nil { game.isPaused = false }
            return .handled
        }
        .onAppear {
            isFocused = true
        }
        .accessibilityElement()
        .accessibilityLabel("pong")
        .accessibilityValue("you \(game.model.playerScore), computer \(game.model.computerScore)")
    }

    private func follow(_ pointer: CGPoint?) {
        guard let pointer else {
            game.isPaused = true
            return
        }
        game.setPlayerPaddle(y: CourtLayout.courtY(forPanelY: pointer.y, in: size))
        if game.model.winner == nil { game.isPaused = false }
    }

    private static func draw(_ game: PongGame, at date: Date, in context: inout GraphicsContext, size: CGSize) {
        let model = game.model
        let court = CourtLayout.rect(in: size)
        guard court.width > 0, court.height > 0 else { return }
        let scaleX = court.width / PongModel.courtSize.width
        let scaleY = court.height / PongModel.courtSize.height
        let paddleWidth: CGFloat = 5
        let paddleHeight = PongModel.paddleHeight * scaleY

        var centerLine = Path()
        centerLine.move(to: CGPoint(x: court.midX, y: court.minY))
        centerLine.addLine(to: CGPoint(x: court.midX, y: court.maxY))
        context.stroke(
            centerLine,
            with: .color(Palette.paddle.opacity(0.35)),
            style: StrokeStyle(lineWidth: 2, dash: [6, 8])
        )

        // Each paddle sits just behind its face: left of it for the computer, right of it for the player.
        let computerFace = court.minX + PongModel.paddleInset * scaleX
        let playerFace = court.minX + (PongModel.courtSize.width - PongModel.paddleInset) * scaleX
        var paddles = Path()
        for (left, centerY) in [(computerFace - paddleWidth, model.computerY), (playerFace, model.playerY)] {
            paddles.addRoundedRect(
                in: CGRect(
                    x: left,
                    y: court.minY + centerY * scaleY - paddleHeight / 2,
                    width: paddleWidth,
                    height: paddleHeight
                ),
                cornerSize: CGSize(width: paddleWidth / 2, height: paddleWidth / 2)
            )
        }
        glow(paddles, color: Palette.paddle, in: &context)

        // Dimmed while waiting (paused or counting down), so its position still shows.
        let isWaiting = game.isPaused || game.countdown > 0
        do {
            let radius = max(PongModel.ballRadius * scaleY, 4)
            let ballCenter = CGPoint(
                x: court.minX + model.ball.position.x * scaleX,
                y: court.minY + model.ball.position.y * scaleY
            )
            let ball = Path(ellipseIn: CGRect(
                x: ballCenter.x - radius,
                y: ballCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            glow(ball, color: Palette.ball.opacity(isWaiting ? Self.waitingBallOpacity : 1), in: &context)
        }

        let pointAge = game.lastPoint.map { date.timeIntervalSince($0.time) }
        if let point = game.lastPoint, let pointAge {
            drawExplosion(for: point, age: pointAge, in: court, context: &context)
        }
        drawScores(model, scorer: game.lastPoint?.side, pointAge: pointAge, in: court, context: &context)
    }

    /// Pixels bursting back into the court from where the ball went out.
    private static func drawExplosion(
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
    private static func drawScores(
        _ model: PongModel,
        scorer: PongSide?,
        pointAge: TimeInterval?,
        in court: CGRect,
        context: inout GraphicsContext
    ) {
        let pop = ScorePulse.scale(age: pointAge)
        let offset = court.width * 0.08
        let top = court.minY + 12
        drawScore(model.computerScore, at: CGPoint(x: court.midX - offset, y: top),
                  scale: scorer == .computer ? pop : 1, context: &context)
        drawScore(model.playerScore, at: CGPoint(x: court.midX + offset, y: top),
                  scale: scorer == .player ? pop : 1, context: &context)
    }

    private static func drawScore(_ value: Int, at point: CGPoint, scale: CGFloat, context: inout GraphicsContext) {
        let text = Text("\(value)")
            .font(.system(.title3, design: .monospaced))
            .bold()
            .foregroundStyle(Palette.paddle.opacity(0.8))
        context.drawLayer { layer in
            layer.translateBy(x: point.x, y: point.y)
            layer.scaleBy(x: scale, y: scale)
            layer.draw(text, at: .zero)
        }
    }

    private static func glow(_ path: Path, color: Color, in context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: color, radius: 8))
            layer.addFilter(.shadow(color: color, radius: 2))
            layer.fill(path, with: .color(color))
        }
    }
}

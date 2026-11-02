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
    @State private var size = CGSize.zero
    @FocusState private var isFocused: Bool

    private static let keyStep: CGFloat = 0.06

    var body: some View {
        TimelineView(.animation(paused: game.isPaused)) { timeline in
            Canvas { context, canvasSize in
                Self.draw(game.model, in: &context, size: canvasSize)
            }
            .onChange(of: timeline.date) { _, date in
                game.tick(now: date)
            }
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
        .accessibilityLabel("Pong")
        .accessibilityValue("You \(game.model.playerScore), computer \(game.model.computerScore)")
    }

    private func follow(_ pointer: CGPoint?) {
        guard let pointer else {
            game.isPaused = true
            return
        }
        game.setPlayerPaddle(y: CourtLayout.courtY(forPanelY: pointer.y, in: size))
        if game.model.winner == nil { game.isPaused = false }
    }

    private static func draw(_ model: PongModel, in context: inout GraphicsContext, size: CGSize) {
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
        glow(ball, color: Palette.ball, in: &context)

        let score = Text("\(model.computerScore)      \(model.playerScore)")
            .font(.system(.title3, design: .monospaced))
            .bold()
            .foregroundStyle(Palette.paddle.opacity(0.8))
        context.draw(score, at: CGPoint(x: court.midX, y: court.minY + 12))
    }

    private static func glow(_ path: Path, color: Color, in context: inout GraphicsContext) {
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: color, radius: 8))
            layer.addFilter(.shadow(color: color, radius: 2))
            layer.fill(path, with: .color(color))
        }
    }
}

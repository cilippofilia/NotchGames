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
    @AppStorage(PlayerCount.storageKey) private var players = PlayerCount.standard
    @State private var size = CGSize.zero
    @FocusState private var isFocused: Bool

    private static let keyStep: CGFloat = 0.06

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
            MatchCountdownView(
                countdown: game.countdown,
                isRunning: !game.isPaused && game.model.winner == nil,
                panelHeight: size.height
            )
        }
        .overlay {
            MatchMessageView(
                winner: game.model.winner,
                isPaused: game.isPaused,
                playerCount: game.playerCount,
                onPlayAgain: game.reset
            )
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
        .onChange(of: players, initial: true) {
            game.playerCount = players
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(keys: [.upArrow, .downArrow, "w", "s"]) { press in
            let isUp = press.key == .upArrow || press.characters == "w"
            let step = isUp ? -Self.keyStep : Self.keyStep
            // With two players W/S drive the left paddle; otherwise every key drives the right one.
            if game.playerCount == .two, press.characters == "w" || press.characters == "s" {
                game.nudgeLeftPaddle(by: step)
            } else {
                game.nudgePlayerPaddle(by: step)
            }
            if game.model.winner == nil { game.isPaused = false }
            return .handled
        }
        .onAppear {
            isFocused = true
            // Only games against the computer count toward the record.
            game.onMatchEnd = { winner, players in
                guard players == .one else { return }
                StatsStore.shared.record(winner: winner)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("pong")
        .accessibilityValue("you \(game.model.playerScore), computer \(game.model.computerScore)")
    }

    private func follow(_ pointer: CGPoint?) {
        let insidePanel = pointer.map { CGRect(origin: .zero, size: size).contains($0) } ?? false
        game.pointerMoved(
            toCourtY: pointer.map { CourtLayout.courtY(forPanelY: $0.y, in: size) },
            insidePanel: insidePanel
        )
    }

    private static func draw(_ game: PongGame, at date: Date, in context: inout GraphicsContext, size: CGSize) {
        let model = game.model
        let court = CourtLayout.rect(in: size)
        guard court.width > 0, court.height > 0 else { return }
        let scaleX = court.width / PongModel.courtSize.width
        let scaleY = court.height / PongModel.courtSize.height
        let paddleWidth: CGFloat = 5
        let paddleHeight = PongModel.paddleHeight * scaleY

        CourtEffects.drawCenterLine(in: court, context: &context)

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
        CourtEffects.glow(paddles, color: Palette.paddle, in: &context)

        drawBall(model.ball, dimmed: game.isPaused || game.countdown > 0, in: court, context: &context)

        CourtEffects.drawEvents(
            (game.lastWallHit, game.lastPoint),
            scores: (computer: model.computerScore, player: model.playerScore),
            at: date,
            in: court,
            context: &context
        )
    }

    /// Dimmed while waiting (paused or counting down), so its position still shows.
    private static func drawBall(_ ball: Ball, dimmed: Bool, in court: CGRect, context: inout GraphicsContext) {
        let scaleX = court.width / PongModel.courtSize.width
        let scaleY = court.height / PongModel.courtSize.height
        let radius = max(PongModel.ballRadius * scaleY, 4)
        let center = CGPoint(x: court.minX + ball.position.x * scaleX, y: court.minY + ball.position.y * scaleY)
        let bounds = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        let shape = Path(ellipseIn: bounds)
        CourtEffects.glow(shape, color: Palette.ball.opacity(dimmed ? CourtEffects.waitingOpacity : 1), in: &context)
    }
}

//
//  PongView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Draws the match in neon and feeds it input: the pointer's height moves the right paddle, arrows or W/S too.
/// The game pauses whenever the pointer leaves the panel.
struct PongView: View {
    let state: PanelState

    @State private var game = PongGame()
    @AppStorage(Difficulty.storageKey(for: .pong)) private var difficulty = Difficulty.standard
    @State private var size = CGSize.zero
    @FocusState private var isFocused: Bool

    var body: some View {
        TimelineView(.animation(paused: game.display.isPaused)) { timeline in
            Canvas { context, canvasSize in
                Self.draw(game, at: timeline.date, in: &context, size: canvasSize)
            }
            .onChange(of: timeline.date) { _, date in
                game.tick(now: date)
            }
        }
        .overlay {
            let display = game.display
            CourtDimView(isDimmed: display.isPaused || display.countdownSeconds > 0 || display.winner != nil)
        }
        .overlay {
            MatchScoreView(
                computer: game.display.computerScore,
                player: game.display.playerScore,
                court: CourtLayout.rect(in: size)
            )
        }
        .overlay(alignment: .center) {
            VStack {
                MatchCountdownView(
                    countdown: TimeInterval(game.display.countdownSeconds),
                    isRunning: !game.display.isPaused && game.display.winner == nil,
                    panelHeight: size.height
                )
                MatchMessageView(
                    winner: game.display.winner,
                    isPaused: game.display.isPaused,
                    isCountingDown: game.display.countdownSeconds > 0,
                    isSettingsOpen: state.isSettingsOpen,
                    streak: StatsStore.shared.stats.matchRecord(for: .pong).currentStreak,
                    onRestart: game.reset
                )
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: state.panelPointer) { _, pointer in
            follow(pointer)
        }
        .onChange(of: difficulty, initial: true) {
            game.difficulty = difficulty
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(keys: [.upArrow, .downArrow, "w", "s"], phases: [.down, .repeat, .up]) { press in
            if game.heldKeys.record(press), game.model.winner == nil { game.isPaused = false }
            return .handled
        }
        .onChange(of: isFocused) { game.heldKeys.releaseAll() }
        .onAppear {
            isFocused = true
            game.onMatchEnd = { StatsStore.shared.record(winner: $0, for: .pong) }
        }
        .accessibilityElement()
        .accessibilityLabel("pong")
        .accessibilityValue("you \(game.display.playerScore), computer \(game.display.computerScore)")
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
        for (left, centerY, color) in [
            (computerFace - paddleWidth, model.computerY, Palette.opponent),
            (playerFace, model.playerY, Palette.player)
        ] {
            let paddle = Path(
                roundedRect: CGRect(
                    x: left,
                    y: court.minY + centerY * scaleY - paddleHeight / 2,
                    width: paddleWidth,
                    height: paddleHeight
                ),
                cornerSize: CGSize(width: paddleWidth / 2, height: paddleWidth / 2)
            )
            CourtEffects.glow(paddle, color: color, in: &context)
        }

        // The trail freezes while waiting, so hide it rather than leave a stuck streak.
        if !game.isPaused, game.countdown <= 0 {
            let centers = game.ballTrail.map {
                CGPoint(x: court.minX + $0.position.x * scaleX, y: court.minY + $0.position.y * scaleY)
            }
            CourtEffects.drawTrail(centers, radius: max(PongModel.ballRadius * scaleY, 4), in: &context)
        }
        drawBall(model.ball, dimmed: game.isPaused || game.countdown > 0, in: court, context: &context)

        CourtEffects.drawEvents(
            (game.lastWallHit, game.lastPoint),
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

#Preview {
    PongView(state: PanelState())
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

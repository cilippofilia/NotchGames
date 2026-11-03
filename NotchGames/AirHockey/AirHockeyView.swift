//
//  AirHockeyView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Draws an air hockey match in neon and feeds it input: the pointer steers the right mallet anywhere in its half,
/// the arrow keys or W/A/S/D too. The game pauses when the pointer leaves.
struct AirHockeyView: View {
    let state: PanelState

    @State private var game = AirHockeyGame()
    @AppStorage(Difficulty.storageKey(for: .airHockey)) private var difficulty = Difficulty.standard
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
        .overlay {
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
                    streak: StatsStore.shared.stats.matchRecord(for: .airHockey).currentStreak,
                    onRestart: game.reset
                )
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: state.panelPointer) { _, pointer in
            let insidePanel = pointer.map { CGRect(origin: .zero, size: size).contains($0) } ?? false
            game.pointerMoved(
                to: pointer.map { CourtLayout.courtPoint(forPanelPoint: $0, in: size) },
                insidePanel: insidePanel
            )
        }
        .onChange(of: difficulty, initial: true) {
            game.difficulty = difficulty
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(
            keys: [.upArrow, .downArrow, .leftArrow, .rightArrow, "w", "a", "s", "d"],
            phases: [.down, .repeat, .up]
        ) { press in
            if game.heldKeys.record(press), game.winner == nil { game.isPaused = false }
            return .handled
        }
        .onChange(of: isFocused) { game.heldKeys.releaseAll() }
        .onAppear {
            isFocused = true
            game.onMatchEnd = { StatsStore.shared.record(winner: $0, for: .airHockey) }
        }
        .accessibilityElement()
        .accessibilityLabel("air hockey")
        .accessibilityValue("you \(game.display.playerScore), computer \(game.display.computerScore)")
    }

    private static func draw(_ game: AirHockeyGame, at date: Date, in context: inout GraphicsContext, size: CGSize) {
        let model = game.model
        let court = CourtLayout.rect(in: size)
        guard court.width > 0, court.height > 0 else { return }
        let scaleX = court.width / AirHockeyModel.courtSize.width
        let scaleY = court.height / AirHockeyModel.courtSize.height
        let unit = min(scaleX, scaleY)
        func place(_ point: CGPoint) -> CGPoint {
            CGPoint(x: court.minX + point.x * scaleX, y: court.minY + point.y * scaleY)
        }

        drawRink(in: court, scaleY: scaleY, context: &context)

        var mallets = Path()
        for mallet in [model.computerMallet, model.playerMallet] {
            let center = place(mallet)
            let radius = AirHockeyModel.malletRadius * unit
            let bounds = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            mallets.addEllipse(in: bounds)
        }
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Palette.paddle, radius: 8))
            layer.stroke(mallets, with: .color(Palette.paddle), lineWidth: 3)
        }

        let puckCenter = place(model.puck.position)
        let puckRadius = max(AirHockeyModel.puckRadius * unit, 5)
        let puck = Path(ellipseIn: CGRect(
            x: puckCenter.x - puckRadius,
            y: puckCenter.y - puckRadius,
            width: puckRadius * 2,
            height: puckRadius * 2
        ))
        let waiting = game.isPaused || game.countdown > 0
        // The trail freezes while waiting, so hide it rather than leave a stuck streak.
        if !waiting {
            CourtEffects.drawTrail(game.puckTrail.map { place($0.position) }, radius: puckRadius, in: &context)
        }
        CourtEffects.glow(puck, color: Palette.ball.opacity(waiting ? CourtEffects.waitingOpacity : 1), in: &context)

        CourtEffects.drawEvents(
            (game.lastWallHit, game.lastPoint),
            at: date,
            in: court,
            context: &context
        )
    }

    /// Bright goal mouths at both ends, the center line and the center circle.
    private static func drawRink(in court: CGRect, scaleY: CGFloat, context: inout GraphicsContext) {
        CourtEffects.drawCenterLine(in: court, context: &context)
        let goalTop = court.minY + (AirHockeyModel.courtSize.height / 2 - AirHockeyModel.goalHalfHeight) * scaleY
        let goalBottom = court.minY + (AirHockeyModel.courtSize.height / 2 + AirHockeyModel.goalHalfHeight) * scaleY

        let circleRadius = court.height * 0.15
        context.stroke(
            Path(ellipseIn: CGRect(
                x: court.midX - circleRadius,
                y: court.midY - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2
            )),
            with: .color(Palette.paddle.opacity(0.35)),
            style: StrokeStyle(lineWidth: 2, dash: [6, 8])
        )

        var goals = Path()
        for edge in [court.minX, court.maxX] {
            goals.move(to: CGPoint(x: edge, y: goalTop))
            goals.addLine(to: CGPoint(x: edge, y: goalBottom))
        }
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: Palette.paddle, radius: 6))
            layer.stroke(goals, with: .color(Palette.paddle), lineWidth: 4)
        }
    }
}

#Preview {
    AirHockeyView(state: PanelState())
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

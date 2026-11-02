//
//  AirHockeyView.swift
//  NotchPong
//
//  Created by Filippo Cilia on 11/2/26.
//

import SwiftUI

/// Draws an air hockey match in neon and feeds it input: the pointer steers the right mallet anywhere in its half,
/// the arrow keys too; with two players W/A/S/D steer the left mallet. The game pauses when the pointer leaves.
struct AirHockeyView: View {
    let state: PanelState

    @State private var game = AirHockeyGame()
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
                isRunning: !game.isPaused && game.winner == nil,
                panelHeight: size.height
            )
        }
        .overlay {
            MatchMessageView(
                winner: game.winner,
                isPaused: game.isPaused,
                playerCount: game.playerCount,
                onPlayAgain: game.reset
            )
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: state.panelPointer) { _, pointer in
            let insidePanel = pointer.map { CGRect(origin: .zero, size: size).contains($0) } ?? false
            game.pointerMoved(
                to: pointer.map { CourtLayout.courtPoint(forPanelPoint: $0, in: size) },
                insidePanel: insidePanel
            )
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
        .onKeyPress(keys: [.upArrow, .downArrow, .leftArrow, .rightArrow, "w", "a", "s", "d"]) { press in
            steer(with: press)
            return .handled
        }
        .onAppear {
            isFocused = true
            // Only games against the computer count toward the record.
            game.onMatchEnd = { [weak game] winner in
                guard game?.playerCount == .one else { return }
                StatsStore.shared.record(winner: winner)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("air hockey")
        .accessibilityValue("you \(game.model.playerScore), computer \(game.model.computerScore)")
    }

    private func steer(with press: KeyPress) {
        let step = Self.keyStep
        let isLetter = ["w", "a", "s", "d"].contains(press.characters)
        let delta: CGVector = switch (press.key, press.characters) {
        case (.upArrow, _), (_, "w"): CGVector(dx: 0, dy: -step)
        case (.downArrow, _), (_, "s"): CGVector(dx: 0, dy: step)
        case (.leftArrow, _), (_, "a"): CGVector(dx: -step, dy: 0)
        default: CGVector(dx: step, dy: 0)
        }
        // With two players W/A/S/D steer the left mallet; otherwise every key steers the right one.
        if game.playerCount == .two, isLetter {
            game.nudgeLeftAim(by: delta)
        } else {
            game.nudgeAim(by: delta)
        }
        if game.winner == nil { game.isPaused = false }
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
        CourtEffects.glow(puck, color: Palette.ball.opacity(waiting ? CourtEffects.waitingOpacity : 1), in: &context)

        CourtEffects.drawEvents(
            (game.lastWallHit, game.lastPoint),
            scores: (computer: model.computerScore, player: model.playerScore),
            at: date,
            in: court,
            context: &context
        )
    }

    /// Faint walls, bright goal mouths at both ends, the center line and the center circle.
    private static func drawRink(in court: CGRect, scaleY: CGFloat, context: inout GraphicsContext) {
        CourtEffects.drawCenterLine(in: court, context: &context)
        let goalTop = court.minY + (AirHockeyModel.courtSize.height / 2 - AirHockeyModel.goalHalfHeight) * scaleY
        let goalBottom = court.minY + (AirHockeyModel.courtSize.height / 2 + AirHockeyModel.goalHalfHeight) * scaleY

        var walls = Path()
        walls.addRect(court)
        context.stroke(walls, with: .color(Palette.paddle.opacity(0.15)), lineWidth: 1)

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

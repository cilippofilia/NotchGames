//
//  SnakeView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Draws the snake in neon and feeds it keys, its only input: arrows or W/A/S/D steer and start, space pauses,
/// return plays again. The pointer does nothing here. It pauses when the panel closes, Settings opens,
/// or the keyboard goes elsewhere.
struct SnakeView: View {
    let state: PanelState

    @State private var game = SnakeGame()
    @AppStorage(SnakeGame.wallsStorageKey) private var hasWalls = true
    @State private var size = CGSize.zero
    @FocusState private var isFocused: Bool

    /// How far the border sits in from the panel's edges, the same on every side.
    private static let borderInset: CGFloat = 6
    private static let gridPadding: CGFloat = 8

    var body: some View {
        let display = game.display
        TimelineView(.animation(paused: display.isPaused)) { timeline in
            Canvas { context, canvasSize in
                // Reading the date ties each redraw to the timeline, so the snake is drawn fresh every frame.
                _ = timeline.date
                Self.draw(game.model, in: &context, size: canvasSize)
            }
            .onChange(of: timeline.date) { _, date in
                game.tick(now: date)
            }
        }
        .overlay {
            CourtDimView(isDimmed: display.isPaused || display.countdownSeconds > 0 || display.isOver)
        }
        .overlay(alignment: .top) {
            HStack(alignment: .firstTextBaseline) {
                ScoreNumber(value: display.score)
                ScoreLabel(text: "best \(display.best)")
            }
            .padding(.top, CourtLayout.rect(in: size).minY)
            .accessibilityHidden(true)
        }
        .overlay(alignment: .center) {
            VStack {
                MatchCountdownView(
                    countdown: TimeInterval(display.countdownSeconds),
                    isRunning: !display.isPaused && !display.isOver,
                    panelHeight: size.height
                )
                MatchMessageView(
                    winner: nil,
                    isPaused: display.isPaused,
                    isCountingDown: display.countdownSeconds > 0,
                    isSettingsOpen: state.isSettingsOpen,
                    runResult: display.isOver
                        ? RunResult(score: display.score, best: display.best, isNewBest: display.isNewBest)
                        : nil,
                    resumeHint: "press an arrow to play",
                    onRestart: game.reset
                )
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(
            keys: [.upArrow, .downArrow, .leftArrow, .rightArrow, "w", "a", "s", "d"],
            phases: .down
        ) { press in
            guard let direction = HeldKeys.direction(key: press.key, characters: press.characters) else {
                return .ignored
            }
            game.press(direction)
            return .handled
        }
        .onKeyPress(.space) {
            game.togglePause()
            return .handled
        }
        .onKeyPress(.return) {
            guard display.isOver else { return .ignored }
            game.reset()
            return .handled
        }
        .onChange(of: hasWalls, initial: true) {
            game.hasWalls = hasWalls
        }
        // The panel stays mounted while closed, so take the keyboard back each time it opens.
        .onChange(of: state.phase, initial: true) { _, phase in
            if phase == .open {
                isFocused = true
            } else {
                game.isPaused = true
            }
        }
        .onChange(of: state.isSettingsOpen) { _, isOpen in
            if isOpen {
                game.isPaused = true
            } else if state.phase == .open {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { game.isPaused = true }
        }
        .onAppear {
            isFocused = true
        }
        .accessibilityElement()
        .accessibilityLabel("snake")
        .accessibilityValue("score \(display.score)")
    }

    private static func draw(_ model: SnakeModel, in context: inout GraphicsContext, size: CGSize) {
        // The panel's body starts below the neck curving out of the notch. The border is inset evenly from it,
        // with its corner radius reduced by the same amount, so it stays concentric with the panel's corners.
        let neck = DropGeometry.neckRadius
        let panelBody = CGRect(x: 0, y: neck, width: size.width, height: size.height - neck)
        let frame = panelBody.insetBy(dx: Self.borderInset, dy: Self.borderInset)
        // Padding keeps the grid's corner cells clear of the border's rounded corners.
        let court = frame.insetBy(dx: Self.gridPadding, dy: Self.gridPadding)
        let cell = min(court.width / CGFloat(SnakeModel.columns), court.height / CGFloat(SnakeModel.rows))
        guard cell > 0 else { return }
        let grid = CGRect(
            x: court.midX - cell * CGFloat(SnakeModel.columns) / 2,
            y: court.midY - cell * CGFloat(SnakeModel.rows) / 2,
            width: cell * CGFloat(SnakeModel.columns),
            height: cell * CGFloat(SnakeModel.rows)
        )
        func square(_ spot: GridCell) -> CGRect {
            let origin = CGPoint(x: grid.minX + CGFloat(spot.column) * cell, y: grid.minY + CGFloat(spot.row) * cell)
            return CGRect(origin: origin, size: CGSize(width: cell, height: cell)).insetBy(dx: 1, dy: 1)
        }

        // Solid walls when they end the run, a faint dashed edge when the snake wraps through.
        let border = Path(roundedRect: frame, cornerRadius: DropGeometry.cornerRadius - Self.borderInset)
        if model.hasWalls {
            let wall = border.strokedPath(StrokeStyle(lineWidth: 2))
            CourtEffects.glow(wall, color: Palette.paddle.opacity(0.6), in: &context)
        } else {
            let edge = StrokeStyle(lineWidth: 1, dash: [4, 4])
            context.stroke(border, with: .color(Palette.paddle.opacity(0.25)), style: edge)
        }

        let corner = CGSize(width: cell * 0.25, height: cell * 0.25)
        var body = Path()
        for segment in model.body.dropFirst() {
            body.addRoundedRect(in: square(segment), cornerSize: corner)
        }
        CourtEffects.glow(body, color: Palette.paddle.opacity(0.8), in: &context)
        let head = Path(roundedRect: square(model.head), cornerSize: corner)
        CourtEffects.glow(head, color: Palette.paddle, in: &context)
        CourtEffects.glow(Path(ellipseIn: square(model.food).insetBy(dx: 1, dy: 1)), color: Palette.ball, in: &context)
    }
}

#Preview {
    SnakeView(state: PanelState())
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

//
//  RunnerView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Draws the run in neon and feeds it keys, its only input: space, up or W to jump (hold for higher), down or S to
/// duck (or drop faster in the air), escape to pause, return to play again. Like Snake, it pauses when the panel
/// closes, Settings opens, or the keyboard goes elsewhere.
struct RunnerView: View {
    let state: PanelState

    @State private var game = RunnerGame()
    @State private var size = CGSize.zero
    @FocusState private var isFocused: Bool

    var body: some View {
        let display = game.display
        TimelineView(.animation(paused: display.isPaused)) { timeline in
            Canvas { context, canvasSize in
                // Reading the date ties each redraw to the timeline, so the street is drawn fresh every frame.
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
                    resumeHint: "press space to play",
                    onRestart: game.reset
                )
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(keys: [.space, .upArrow, "w"], phases: [.down, .repeat, .up]) { press in
            game.isJumpHeld = press.phase != .up
            if press.phase == .down { game.jumpPressed() }
            return .handled
        }
        .onKeyPress(keys: [.downArrow, "s"], phases: [.down, .repeat, .up]) { press in
            game.isDuckHeld = press.phase != .up
            return .handled
        }
        .onKeyPress(.escape) {
            game.togglePause()
            return .handled
        }
        .onKeyPress(.return) {
            guard display.isOver else { return .ignored }
            game.reset()
            return .handled
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
            game.releaseKeys()
            if !focused { game.isPaused = true }
        }
        .onAppear {
            isFocused = true
        }
        .accessibilityElement()
        .accessibilityLabel("runner")
        .accessibilityValue("score \(display.score)")
    }
}

// MARK: - Drawing

extension RunnerView {
    /// How far down the court the ground sits; the rest above is room to jump.
    private static let groundLevel: CGFloat = 0.78

    private static func draw(_ model: RunnerModel, in context: inout GraphicsContext, size: CGSize) {
        let court = CourtLayout.rect(in: size)
        let scale = min(court.width / RunnerModel.courtWidth, court.height)
        guard scale > 0 else { return }
        let originX = court.midX - RunnerModel.courtWidth * scale / 2
        let groundY = court.minY + court.height * groundLevel
        // Court boxes measure y up from the ground; the view's y runs down.
        func place(_ box: CGRect) -> CGRect {
            CGRect(
                x: originX + box.minX * scale,
                y: groundY - box.maxY * scale,
                width: box.width * scale,
                height: box.height * scale
            )
        }
        context.clip(to: Path(court))

        drawGround(at: groundY, in: court, scrolled: model.distance * scale, context: &context)

        var obstacles = Path()
        let pigeonFrame = Int(model.distance * 8) % 2
        for obstacle in model.obstacles {
            let rows = sprite(for: obstacle.kind, frame: pigeonFrame)
            let single = obstacle.kind.size.width
            for index in 0..<obstacle.count {
                let left = obstacle.minX + CGFloat(index) * (single + RunnerModel.coneGap)
                let box = CGRect(x: left, y: obstacle.kind.altitude, width: single, height: obstacle.kind.size.height)
                obstacles.addPath(pixels(rows, in: place(box)))
            }
        }
        CourtEffects.glow(obstacles, color: Palette.ball, in: &context)

        let skater = place(model.skaterBox)
        let skaterPath = pixels(model.isDucking ? RunnerSprites.ducking : RunnerSprites.skater, in: skater)
        if model.isOver {
            // The board goes flying: tip the skater over where they hit.
            var tumble = context
            tumble.translateBy(x: skater.midX, y: skater.maxY)
            tumble.rotate(by: .degrees(-70))
            tumble.translateBy(x: -skater.midX, y: -skater.maxY)
            CourtEffects.glow(skaterPath, color: Palette.paddle, in: &tumble)
        } else {
            CourtEffects.glow(skaterPath, color: Palette.paddle, in: &context)
        }
    }

    private static func sprite(for kind: RunnerObstacle.Kind, frame: Int) -> [String] {
        switch kind {
        case .cone: RunnerSprites.cone
        case .bench: RunnerSprites.bench
        case .pigeon: RunnerSprites.pigeon[frame]
        case .cart: RunnerSprites.cart
        }
    }

    /// A glowing ground line with dashes underneath that scroll with the street, so speed reads at a glance.
    private static func drawGround(
        at groundY: CGFloat,
        in court: CGRect,
        scrolled: CGFloat,
        context: inout GraphicsContext
    ) {
        var ground = Path()
        ground.move(to: CGPoint(x: court.minX, y: groundY))
        ground.addLine(to: CGPoint(x: court.maxX, y: groundY))
        let line = ground.strokedPath(StrokeStyle(lineWidth: 1.5))
        CourtEffects.glow(line, color: Palette.paddle.opacity(0.5), in: &context)

        var dashes = Path()
        dashes.move(to: CGPoint(x: court.minX, y: groundY + 8))
        dashes.addLine(to: CGPoint(x: court.maxX, y: groundY + 8))
        let style = StrokeStyle(lineWidth: 1, dash: [6, 14], dashPhase: scrolled)
        context.stroke(dashes, with: .color(Palette.paddle.opacity(0.25)), style: style)
    }

    /// One small square per lit pixel of `rows`, stretched to fill `rect`.
    private static func pixels(_ rows: [String], in rect: CGRect) -> Path {
        var path = Path()
        let columns = CGFloat(rows.first?.count ?? 1)
        let width = rect.width / columns
        let height = rect.height / CGFloat(rows.count)
        for (row, line) in rows.enumerated() {
            for (column, character) in line.enumerated() where character != "." {
                path.addRect(CGRect(
                    x: rect.minX + CGFloat(column) * width,
                    y: rect.minY + CGFloat(row) * height,
                    width: width,
                    height: height
                ).insetBy(dx: width * 0.08, dy: height * 0.08))
            }
        }
        return path
    }
}

#Preview {
    RunnerView(state: PanelState())
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

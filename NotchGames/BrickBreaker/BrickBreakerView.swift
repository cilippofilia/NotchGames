//
//  BrickBreakerView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Draws the run in neon and feeds it input: the pointer's left–right position moves the paddle, arrows or A/D too.
/// The game pauses whenever the pointer leaves the panel.
struct BrickBreakerView: View {
    let state: PanelState

    @State private var game = BrickBreakerGame()
    @State private var size = CGSize.zero
    @FocusState private var isFocused: Bool

    private static let keyStep: CGFloat = 0.06

    var body: some View {
        let display = game.display
        TimelineView(.animation(paused: display.isPaused)) { timeline in
            Canvas { context, canvasSize in
                Self.draw(game, at: timeline.date, in: &context, size: canvasSize)
            }
            .onChange(of: timeline.date) { _, date in
                game.tick(now: date)
            }
        }
        .overlay(alignment: .top) {
            HStack(alignment: .firstTextBaseline) {
                LivesView(lives: display.lives)
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
                    onRestart: game.reset
                )
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: state.panelPointer) { _, pointer in
            follow(pointer)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(keys: [.leftArrow, .rightArrow, "a", "d"]) { press in
            let isLeft = press.key == .leftArrow || press.characters == "a"
            game.nudge(by: isLeft ? -Self.keyStep : Self.keyStep)
            if !game.model.isOver { game.isPaused = false }
            return .handled
        }
        .onAppear {
            isFocused = true
        }
        .accessibilityElement()
        .accessibilityLabel("brick breaker")
        .accessibilityValue("score \(display.score), \(display.lives) lives")
    }

    private func follow(_ pointer: CGPoint?) {
        let insidePanel = pointer.map { CGRect(origin: .zero, size: size).contains($0) } ?? false
        let courtWidth = BrickBreakerModel.courtSize.width
        let inset = CourtLayout.edgeInset
        game.pointerMoved(
            toCourtX: pointer.map {
                CourtLayout.courtPoint(forPanelPoint: $0, in: size, courtWidth: courtWidth, sideInset: inset).x
            },
            insidePanel: insidePanel
        )
    }

    private static func draw(_ game: BrickBreakerGame, at date: Date, in context: inout GraphicsContext, size: CGSize) {
        let model = game.model
        let court = CourtLayout.rect(in: size, sideInset: CourtLayout.edgeInset)
        guard court.width > 0, court.height > 0 else { return }
        let courtWidth = BrickBreakerModel.courtSize.width
        let scaleX = court.width / courtWidth
        let scaleY = court.height / BrickBreakerModel.courtSize.height
        func place(_ rect: CGRect) -> CGRect {
            CGRect(
                x: court.minX + rect.minX * scaleX,
                y: court.minY + rect.minY * scaleY,
                width: rect.width * scaleX,
                height: rect.height * scaleY
            )
        }

        drawWall(model.wall, slide: game.rowSlide, place: place, context: &context)

        drawPaddle(at: model.paddleX, place: place, context: &context)

        let waiting = game.isPaused || game.countdown > 0
        let radius = max(BrickBreakerModel.ballRadius * scaleY, 4)
        func center(_ point: CGPoint) -> CGPoint {
            CGPoint(x: court.minX + point.x * scaleX, y: court.minY + point.y * scaleY)
        }
        // The trail freezes while waiting, so hide it rather than leave a stuck streak.
        if !waiting {
            CourtEffects.drawTrail(game.ballTrail.map { center($0.position) }, radius: radius, in: &context)
        }
        let ball = center(model.ball.position)
        CourtEffects.glow(
            Path(ellipseIn: CGRect(x: ball.x - radius, y: ball.y - radius, width: radius * 2, height: radius * 2)),
            color: Palette.ball.opacity(waiting ? CourtEffects.waitingOpacity : 1),
            in: &context
        )

        for hit in [game.lastWallHit, game.lastBrickHit].compactMap({ $0 }) {
            CourtEffects.drawWallSpark(
                for: hit,
                age: date.timeIntervalSince(hit.time),
                in: court,
                courtWidth: courtWidth,
                context: &context
            )
        }
    }
}

// MARK: - Drawing helpers

extension BrickBreakerView {
    /// A new row slides in from above, so the whole wall starts one row higher and eases down.
    private static func drawWall(
        _ wall: BrickWall,
        slide: CGFloat,
        place: (CGRect) -> CGRect,
        context: inout GraphicsContext
    ) {
        let shift = slide * (BrickWall.rowHeight + BrickWall.gap)
        var bricks = Path()
        for (row, columns) in wall.rows.enumerated() {
            for (column, isStanding) in columns.enumerated() where isStanding {
                let brick = wall.rect(row: row, column: column, courtWidth: BrickBreakerModel.courtSize.width)
                let corner = CGSize(width: 2, height: 2)
                bricks.addRoundedRect(in: place(brick.offsetBy(dx: 0, dy: -shift)), cornerSize: corner)
            }
        }
        CourtEffects.glow(bricks, color: Palette.ball.opacity(0.85), in: &context)
    }

    private static func drawPaddle(at centerX: CGFloat, place: (CGRect) -> CGRect, context: inout GraphicsContext) {
        let paddle = place(CGRect(
            x: centerX - BrickBreakerModel.paddleWidth / 2,
            y: BrickBreakerModel.paddleTop,
            width: BrickBreakerModel.paddleWidth,
            height: BrickBreakerModel.paddleHeight
        ))
        let radius = paddle.height / 2
        CourtEffects.glow(
            Path(roundedRect: paddle, cornerSize: CGSize(width: radius, height: radius)),
            color: Palette.paddle,
            in: &context
        )
    }
}

#Preview {
    BrickBreakerView(state: PanelState())
        .frame(width: 368, height: 460)
        .background(Palette.background)
}

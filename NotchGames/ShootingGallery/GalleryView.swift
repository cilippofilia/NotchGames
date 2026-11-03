//
//  GalleryView.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

import SwiftUI

/// Draws the shooting gallery in neon and feeds it the pointer, its only input: a teal crosshair follows the
/// pointer and a click shoots. It pauses whenever the pointer leaves the panel.
struct GalleryView: View {
    let state: PanelState

    @State private var game = GalleryGame()
    @State private var size = CGSize.zero
    /// A press shoots once, on the way down; this waits for the release before the next.
    @State private var isPressing = false

    var body: some View {
        let display = game.display
        TimelineView(.animation(paused: display.run.isPaused)) { timeline in
            Canvas { context, canvasSize in
                Self.draw(game, pointer: state.panelPointer, at: timeline.date, in: &context, size: canvasSize)
            }
            .onChange(of: timeline.date) { _, date in
                game.tick(now: date)
            }
        }
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    guard !isPressing else { return }
                    isPressing = true
                    // Between rounds, a click on the court starts the next one.
                    if game.display.summary != nil {
                        game.continueToNextRound()
                        return
                    }
                    game.shoot(at: Self.courtPoint(for: drag.location, in: size), now: .now)
                }
                .onEnded { _ in isPressing = false }
        )
        .overlay {
            CourtDimView(isDimmed: display.run.isPaused || display.run.countdownSeconds > 0 || display.run.isOver)
        }
        .overlay(alignment: .top) {
            GalleryHUDView(display: display)
                .padding(.top, CourtLayout.rect(in: size).minY)
                .padding(.horizontal, CourtLayout.rect(in: size).minX)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .center) {
            if let summary = display.summary {
                RoundSummaryView(summary: summary, onContinue: game.continueToNextRound)
            } else {
                VStack {
                    MatchCountdownView(
                        countdown: TimeInterval(display.run.countdownSeconds),
                        isRunning: !display.run.isPaused && !display.run.isOver,
                        panelHeight: size.height
                    )
                    MatchMessageView(
                        winner: nil,
                        isPaused: display.run.isPaused,
                        isCountingDown: display.run.countdownSeconds > 0,
                        isSettingsOpen: state.isSettingsOpen,
                        runResult: display.run.isOver
                            ? RunResult(
                                score: display.run.score,
                                best: display.run.best,
                                isNewBest: display.run.isNewBest
                            )
                            : nil,
                        onRestart: game.reset
                    )
                }
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .onChange(of: state.panelPointer) { _, pointer in
            game.pointerMoved(insidePanel: pointer.map { CGRect(origin: .zero, size: size).contains($0) })
        }
        .accessibilityElement()
        .accessibilityLabel("shooting gallery")
        .accessibilityValue("round \(display.round), score \(display.run.score), \(display.shotsLeft) shots left")
    }

    /// Panel points to court units (1.6 × 1, y down).
    private static func courtPoint(for location: CGPoint, in size: CGSize) -> CGPoint {
        let court = CourtLayout.rect(in: size)
        guard court.width > 0, court.height > 0 else { return .zero }
        return CGPoint(
            x: (location.x - court.minX) / court.width * GalleryModel.courtSize.width,
            y: (location.y - court.minY) / court.height * GalleryModel.courtSize.height
        )
    }
}

// MARK: - Drawing

extension GalleryView {
    private static let flashLength: TimeInterval = 0.08
    private static let missRingLength: TimeInterval = 0.35

    private static func draw(
        _ game: GalleryGame,
        pointer: CGPoint?,
        at date: Date,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let court = CourtLayout.rect(in: size)
        guard court.width > 0, court.height > 0 else { return }
        let scaleX = court.width / GalleryModel.courtSize.width
        let scaleY = court.height / GalleryModel.courtSize.height
        func place(_ point: CGPoint) -> CGPoint {
            CGPoint(x: court.minX + point.x * scaleX, y: court.minY + point.y * scaleY)
        }

        // The shot's flash lights the whole court for a moment.
        if let shotTime = game.lastShotTime, date.timeIntervalSince(shotTime) < flashLength {
            let fade = 1 - date.timeIntervalSince(shotTime) / flashLength
            context.fill(Path(court), with: .color(Palette.paddle.opacity(0.12 * fade)))
        }

        var ground = Path()
        ground.move(to: place(CGPoint(x: 0, y: GalleryModel.groundY)))
        ground.addLine(to: place(CGPoint(x: GalleryModel.courtSize.width, y: GalleryModel.groundY)))
        let groundLine = ground.strokedPath(StrokeStyle(lineWidth: 1.5))
        CourtEffects.glow(groundLine, color: Palette.paddle.opacity(0.5), in: &context)

        let scale = CGSize(width: scaleX, height: scaleY)
        drawBirds(game.model.birds, at: date, place: place, scale: scale, context: &context)

        if let hit = game.lastHit {
            CourtEffects.drawWallSpark(
                for: hit,
                age: date.timeIntervalSince(hit.time),
                in: court,
                courtWidth: GalleryModel.courtSize.width,
                context: &context
            )
        }
        if let miss = game.lastMiss, date.timeIntervalSince(miss.time) < missRingLength {
            let age = date.timeIntervalSince(miss.time) / missRingLength
            let radius = 6 + 10 * age
            let center = place(miss.position)
            let ring = Path(ellipseIn: CGRect(origin: center, size: .zero).insetBy(dx: -radius, dy: -radius))
            context.stroke(ring, with: .color(Palette.paddle.opacity(0.6 * (1 - age))), lineWidth: 1.5)
        }

        if let pointer, court.contains(pointer), !game.isPaused {
            drawCrosshair(at: pointer, context: &context)
        }
    }

    private static func drawBirds(
        _ birds: [GalleryBird],
        at date: Date,
        place: (CGPoint) -> CGPoint,
        scale: CGSize,
        context: inout GraphicsContext
    ) {
        let width = GalleryModel.birdSize.width * scale.width
        let height = GalleryModel.birdSize.height * scale.height
        let flap = Int(date.timeIntervalSinceReferenceDate * 8) % 2
        for bird in birds {
            let center = place(bird.position)
            let frame = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
            let rows = bird.phase == .falling ? GallerySprites.bird[0] : GallerySprites.bird[flap]
            // Face the way it's flying; a shot bird tumbles upside down.
            let facesLeft = bird.velocity.dx < 0
            var layer = context
            layer.translateBy(x: center.x, y: center.y)
            layer.scaleBy(x: facesLeft ? -1 : 1, y: bird.phase == .falling ? -1 : 1)
            layer.translateBy(x: -center.x, y: -center.y)
            let color = bird.phase == .falling ? Palette.ball.opacity(0.5) : Palette.ball
            CourtEffects.glow(GallerySprites.path(for: rows, in: frame), color: color, in: &layer)
        }
    }

    private static func drawCrosshair(at point: CGPoint, context: inout GraphicsContext) {
        let radius: CGFloat = 10
        var sight = Path(ellipseIn: CGRect(origin: point, size: .zero).insetBy(dx: -radius, dy: -radius))
        for (across, down) in [(0.0, -1.0), (0, 1), (-1, 0), (1, 0)] {
            sight.move(to: CGPoint(x: point.x + across * radius * 0.5, y: point.y + down * radius * 0.5))
            sight.addLine(to: CGPoint(x: point.x + across * radius * 1.5, y: point.y + down * radius * 1.5))
        }
        CourtEffects.glow(sight.strokedPath(StrokeStyle(lineWidth: 1.5)), color: Palette.paddle, in: &context)
    }
}

#Preview {
    GalleryView(state: PanelState())
        .frame(width: 480, height: 300)
        .background(Palette.background)
}

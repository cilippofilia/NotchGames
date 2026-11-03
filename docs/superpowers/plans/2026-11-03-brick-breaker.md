# Brick Breaker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an endless brick breaker game, in a taller panel, with a best score per game kept between launches.

**Architecture:** Same shape as Pong: a plain-struct model for the physics (`BrickBreakerModel`, with the wall in `BrickWall`), a `@MainActor @Observable` game (`BrickBreakerGame`) that runs `MatchClock` and publishes a small display value, and a `BrickBreakerView` that draws the court in a `Canvas` inside a `TimelineView`. The panel's shape becomes per game: `GameKind.panelAspect` flows through `PanelState.aspect` into the sizing and drop geometry. Best scores live in `PlayerStats`, keyed by `GameKind`.

**Tech Stack:** Swift 6, SwiftUI, macOS 26, Swift Testing, `xcodebuild`.

**Spec:** `docs/superpowers/specs/2026-11-03-brick-breaker-design.md`

## Global Constraints

- macOS 26+, Swift 6 strict concurrency, no third-party code. Follow `~/.claude/CLAUDE.md`: one type per file, `@Observable` classes marked `@MainActor`, `.foregroundStyle`, `Task.sleep(for:)`, no `GeometryReader` when an alternative works, a `#Preview` on every new view.
- Lowercase in-game copy. The game's title is `"brick breaker"`.
- Court units: y from 0 (top) to 1 (bottom), x from 0 to `BrickBreakerModel.courtSize.width` (0.8), drawn into `CourtLayout.rect(in:)`.
- Per-frame state is `@ObservationIgnored`. Views outside the `Canvas` read only the display value, which is republished only when it changes (the `MatchDisplay` pattern, see `PongGame.publishDisplay()`).
- Pong and Air Hockey keep their 1.6 panel and play exactly as before.
- Saved wins, losses and streaks must survive the upgrade.
- Test command for every task: `xcodebuild test -scheme NotchPong -destination 'platform=macOS,arch=arm64' 2>&1 | grep -E "error:|recorded an issue|Test run with|TEST (SUCCEEDED|FAILED)"`. Lint: `swiftlint --quiet` prints nothing.

## Review Focus

1. **Stats saved by the current version** (JSON without `bestScores`) must load with wins, losses and streaks intact. Test in Task 1.
2. **A fast ball at the top speed** must not pass through a brick or the paddle in one frame. Test in Task 4.
3. **A row dropping while the ball is inside the wall** must push the ball below the new row, not trap it. Test in Task 3.
4. **Switching games while the panel is open** must resize the panel to the new shape, and the drop must never be wider than the notch inside the menu bar. Manual check in Task 6.
5. **Pausing mid-run** (pointer leaves, Settings opens, panel closes) must freeze the row timer and the time score. Test in Task 5.

---

### Task 1: Best scores in the saved record

**Files:**
- Modify: `NotchPong/Stats/PlayerStats.swift`, `NotchPong/Stats/StatsStore.swift`, `NotchPong/Stats/StatsSection.swift`
- Test: `NotchPongTests/StatsTests.swift`

**Interfaces:**
- Produces: `PlayerStats.bestScores: [String: Int]` (keyed by `GameKind.rawValue`), `PlayerStats.bestScore(for: GameKind) -> Int` (0 when none), `mutating PlayerStats.recordScore(_ score: Int, for game: GameKind) -> Bool` (true only when strictly higher than the saved best), `StatsStore.recordScore(_ score: Int, for game: GameKind) -> Bool` (records and saves).

- [ ] **Step 1: Write the failing tests** in `StatsTests`:

```swift
@Test func oldSavedStatsStillLoad() throws {
    let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
    defaults.set(Data(#"{"wins":4,"losses":2,"currentStreak":1,"bestStreak":3}"#.utf8), forKey: "stats")
    #expect(StatsStore(defaults: defaults).stats == PlayerStats(wins: 4, losses: 2, currentStreak: 1, bestStreak: 3))
}

@Test func onlyAHigherScoreIsANewBest() {
    var stats = PlayerStats()
    #expect(stats.recordScore(120, for: .brickBreaker))
    #expect(!stats.recordScore(120, for: .brickBreaker))
    #expect(!stats.recordScore(80, for: .brickBreaker))
    #expect(stats.bestScore(for: .brickBreaker) == 120)
    #expect(stats.bestScore(for: .pong) == 0)
}

@Test func bestScoresSaveAndReset() throws {
    let defaults = try #require(UserDefaults(suiteName: "StatsTests-\(UUID())"))
    let store = StatsStore(defaults: defaults)
    _ = store.recordScore(300, for: .brickBreaker)
    #expect(StatsStore(defaults: defaults).stats.bestScore(for: .brickBreaker) == 300)
    store.reset()
    #expect(StatsStore(defaults: defaults).stats.bestScore(for: .brickBreaker) == 0)
}
```

`.brickBreaker` doesn't exist yet: add `case brickBreaker` to `GameKind` now (title `String(localized: "brick breaker")`), and make `GameView` show `Text("brick breaker")` for it until Task 6. Its `panelAspect` arrives in Task 2.

- [ ] **Step 2: Run the tests.** Expected: compile failure on `recordScore` / `bestScore`.
- [ ] **Step 3: Implement.** Add `bestScores` with default `[:]` and a hand-written `init(from:)` that uses `decodeIfPresent` for `bestScores` (the other keys decode as today). Keep the memberwise initializer used by existing tests, for example by giving `bestScores` a default in an explicit `init`. `StatsSection` gets `LabeledContent("brick breaker best", value: store.stats.bestScore(for: .brickBreaker), format: .number)` after "best streak".
- [ ] **Step 4: Run the tests and lint.** Expected: all pass, lint silent.
- [ ] **Step 5: Commit** `feat: keep a best score per game`.

---

### Task 2: Per-game panel shape

**Files:**
- Modify: `NotchPong/Match/GameKind.swift`, `NotchPong/NotchPanel/PullSizing.swift`, `NotchPong/NotchPanel/DropGeometry.swift`, `NotchPong/NotchPanel/DropShape.swift`, `NotchPong/NotchPanel/PanelState.swift`, `NotchPong/NotchPanel/GamePanelView.swift`, `NotchPong/NotchPanel/NotchPanelController.swift`, `NotchPong/Match/GameView.swift`
- Test: `NotchPongTests/PullSizingTests.swift`, `NotchPongTests/DropGeometryTests.swift`

**Interfaces:**
- Produces: `GameKind.panelAspect: CGFloat` (1.6 for `.pong` and `.airHockey`, 0.8 for `.brickBreaker`), `PanelState.aspect: CGFloat = 1.6`, `PullSizing.bodySize(forPull:aspect:) -> CGSize`, `PullSizing.releaseOutcome(pull:upwardVelocity:aspect:)`, `DropGeometry.width(forLength:aspect:)`, `DropGeometry.frameWidth(forLength:notchWidth:dropOffset:aspect:)`, `DropShape.aspect: CGFloat`. `PullSizing.aspect` is removed.

- [ ] **Step 1: Write the failing tests.** Update every existing call in `PullSizingTests` and `DropGeometryTests` to pass `aspect: 1.6` with the same expectations, and add:

```swift
@Test func portraitPanelKeepsItsHeight() {
    #expect(PullSizing.bodySize(forPull: 900, aspect: 0.8) == CGSize(width: 368, height: 460))
}

@Test func portraitDropReachesItsWidthAtFullLength() {
    #expect(DropGeometry.width(forLength: PullSizing.maxBodyHeight, aspect: 0.8) == PullSizing.maxBodyHeight * 0.8)
    #expect(DropGeometry.width(forLength: Magnet.maxLength, aspect: 0.8) == DropGeometry.dripWidth)
}
```

- [ ] **Step 2: Run the tests.** Expected: compile failure on the new `aspect:` labels.
- [ ] **Step 3: Implement.** Thread `aspect` through the functions above; `DropGeometry.width`'s growth uses `PullSizing.maxBodyHeight * aspect` where it used `PullSizing.aspect`. `DropShape` and `GamePanelView` pass `state.aspect`. The controller reads `state.aspect` wherever it sizes the body (`playFromMenu`, `updatePull`, release, `dropRect`). The overlay window width keeps using 1.6, the widest shape. `GameView` sets `state.aspect = game.panelAspect` in `.onChange(of: game, initial: true)`. When `state.aspect` changes while `state.phase == .open`, the controller re-settles to `.open(PullSizing.bodySize(forPull: state.bodySize.height, aspect: state.aspect))`; detect it in the per-frame `step` by comparing `state.bodySize.width` with `state.bodySize.height * state.aspect`.
- [ ] **Step 4: Run the tests and lint.** Expected: all pass.
- [ ] **Step 5: Commit** `feat: let each game pick its panel shape`.

---

### Task 3: The brick wall

**Files:**
- Create: `NotchPong/BrickBreaker/BrickWall.swift`
- Test: `NotchPongTests/BrickWallTests.swift`

**Interfaces:**
- Produces: `nonisolated struct BrickWall: Equatable` with `static let columns = 10`, `static let rowHeight: CGFloat = 0.045`, `static let gap: CGFloat = 0.006`, `static let top: CGFloat = 0.04` (court y of the top row's top edge), `private(set) var rows: [[Bool]]` (index 0 is the top row, `true` is a standing brick), `init(rows: Int)` (that many full rows), `mutating func dropRow()` (inserts a full row at index 0), `func rect(row: Int, column: Int, courtWidth: CGFloat) -> CGRect`, `mutating func breakBrick(row: Int, column: Int)`, `var lowestBrickBottom: CGFloat?` (court y of the bottom edge of the lowest row that still has a brick, nil when empty). Trailing empty rows are removed so `rows` doesn't grow forever.

The smooth slide when a row drops is drawn by the view (Task 6), not modelled here.

- [ ] **Step 1: Write the failing tests:**

```swift
@Test func newWallIsFull() {
    let wall = BrickWall(rows: 3)
    #expect(wall.rows.count == 3)
    #expect(wall.rows.allSatisfy { $0.count == BrickWall.columns && $0.allSatisfy { $0 } })
}

@Test func droppingARowPushesTheWallDown() throws {
    var wall = BrickWall(rows: 2)
    let before = try #require(wall.lowestBrickBottom)
    wall.dropRow()
    let after = try #require(wall.lowestBrickBottom)
    #expect(abs(after - before - (BrickWall.rowHeight + BrickWall.gap)) < 0.0001)
}

@Test func emptiedBottomRowsAreDropped() {
    var wall = BrickWall(rows: 2)
    for column in 0..<BrickWall.columns { wall.breakBrick(row: 1, column: column) }
    #expect(wall.rows.count == 1)
    for column in 0..<BrickWall.columns { wall.breakBrick(row: 0, column: column) }
    #expect(wall.lowestBrickBottom == nil)
}

@Test func bricksTileTheCourtWidth() {
    let wall = BrickWall(rows: 1)
    let first = wall.rect(row: 0, column: 0, courtWidth: 0.8)
    let last = wall.rect(row: 0, column: BrickWall.columns - 1, courtWidth: 0.8)
    #expect(first.minX > 0 && last.maxX < 0.8)
    #expect(first.minY == BrickWall.top)
}
```

- [ ] **Step 2: Run.** Expected: compile failure, `BrickWall` missing.
- [ ] **Step 3: Implement `BrickWall`.** Bricks are evenly sized across the court with `gap` between them and at both sides.
- [ ] **Step 4: Run tests and lint.** Expected: pass.
- [ ] **Step 5: Commit** `feat: add the brick wall`.

---

### Task 4: Brick breaker physics and rules

**Files:**
- Create: `NotchPong/BrickBreaker/BrickBreakerModel.swift`
- Test: `NotchPongTests/BrickBreakerModelTests.swift`

**Interfaces:**
- Consumes: `BrickWall`, `Ball`.
- Produces: `nonisolated struct BrickBreakerModel` with:
  - constants: `courtSize = CGSize(width: 0.8, height: 1.0)`, `paddleWidth: CGFloat = 0.18`, `paddleTop: CGFloat = 0.92`, `paddleHeight: CGFloat = 0.02`, `ballRadius: CGFloat = 0.014`, `startingLives = 3`, `startingRows = 3`, `rowsPerLevel = 5`, `baseBallSpeed: CGFloat = 0.7`, `ballSpeedPerLevel: CGFloat = 0.08`, `maxBallSpeed: CGFloat = 1.5`, `baseRowInterval: TimeInterval = 10`, `rowIntervalPerLevel: TimeInterval = 0.8`, `minRowInterval: TimeInterval = 3`, `brickPoints = 10`, `rowPoints = 25`. These are starting values to tune by playing.
  - state: `var ball: Ball`, `var paddleX: CGFloat` (center), `private(set) var wall: BrickWall`, `private(set) var lives`, `private(set) var score`, `private(set) var rowsDropped`, `private(set) var isOver`, `private(set) var wallBounce: (position: CGPoint, inward: CGVector)?` (as in `AirHockeyModel`), `private(set) var brokenBrick: CGRect?` (last step's broken brick, for the effect), `private(set) var lostBall: Bool` (true for the step a life was lost).
  - computed: `level: Int` (`1 + rowsDropped / rowsPerLevel`), `ballSpeed: CGFloat`, `rowInterval: TimeInterval`.
  - `init(rowsDropped: Int = 0)` (full lives, `rowsDropped` preset so tests can start at a high level, `startingRows` rows, ball served from above the paddle), `mutating func step(by interval: TimeInterval)`, `mutating func dropRow()` (adds `rowPoints`, counts the row, pushes the ball below the new row if it overlaps, ends the run if the wall reaches `paddleTop`), `mutating func addSurvivalPoints(_ points: Int)`, `mutating func serve()` (ball just above the paddle center, moving up at `ballSpeed`, angled 0.3 rad off vertical).

- [ ] **Step 1: Write the failing tests** (one `@Test` each):
  - `ballBouncesOffSideAndTopWalls`: ball heading up-left near the top-left corner ends with `dx > 0` and `dy > 0` after a step; `wallBounce != nil`.
  - `paddleSendsTheBallBackUpAngledByHitPoint`: ball moving down onto the paddle's right half ends with `dy < 0` and `dx > 0`.
  - `brickBreaksAndScoresByLevel`: ball moving up into the lowest row breaks exactly one brick, `score == brickPoints * level`, `dy` flips.
  - `fastBallCannotTunnelThroughABrick`: ball at `maxBallSpeed`, stepped by `MatchClock.maxStep`, starting just below a brick, still breaks it.
  - `fastBallCannotTunnelThroughThePaddle`: same at the paddle.
  - `missedBallCostsALife`: ball below the paddle moving down: after the step `lives == 2` and `lostBall`.
  - `thirdMissEndsTheRun`: three misses give `isOver` and `lives == 0`; `step` afterwards changes nothing.
  - `rowDropAddsPointsAndLevelsUp`: five `dropRow()` calls give `rowsDropped == 5`, `level == 2`, `score == 5 * rowPoints`, `rowInterval == baseRowInterval - rowIntervalPerLevel`, `ballSpeed == baseBallSpeed + ballSpeedPerLevel`.
  - `rowIntervalAndSpeedAreCapped`: `BrickBreakerModel(rowsDropped: 500)` has `rowInterval == minRowInterval` and `ballSpeed == maxBallSpeed`.
  - `wallReachingThePaddleEndsTheRun`: keep calling `dropRow()` without breaking bricks until `isOver`; at that point `wall.lowestBrickBottom! >= paddleTop`.
  - `rowDroppingOnTheBallPushesItBelow`: ball placed inside the wall's lowest row area, `dropRow()`, then the ball's top (`y - ballRadius`) is below `wall.lowestBrickBottom!` and its velocity is unchanged.
- [ ] **Step 2: Run.** Expected: compile failure.
- [ ] **Step 3: Implement.** Split each step into substeps so the ball moves at most `ballRadius` per substep (the same idea as `AirHockeyModel`'s substeps). In each substep: move, bounce off the side and top walls, then test the ball circle against each standing brick's rect; on overlap break that one brick, reflect on the axis of least penetration and stop checking bricks for this substep. Paddle: when the ball is moving down and crosses `paddleTop` within the paddle's x span (plus `ballRadius`), reflect upward at an angle set by the hit offset, as `PongModel.bounce` does (max 60°), keeping `ballSpeed`. Past the bottom edge: lose a life, set `lostBall`, `isOver` at 0 lives, otherwise `serve()`. Clamp `paddleX` so the paddle stays inside the court.
- [ ] **Step 4: Run tests and lint.** Expected: pass.
- [ ] **Step 5: Commit** `feat: add brick breaker physics and rules`.

---

### Task 5: The game loop

**Files:**
- Create: `NotchPong/BrickBreaker/BrickBreakerGame.swift`, `NotchPong/BrickBreaker/BrickBreakerDisplay.swift`
- Test: `NotchPongTests/BrickBreakerGameTests.swift`

**Interfaces:**
- Consumes: `BrickBreakerModel`, `MatchClock`, `StatsStore.recordScore(_:for:)`, `WallHit`, `PongGame.trailLength`.
- Produces:
  - `nonisolated struct BrickBreakerDisplay: Equatable { var isPaused = true; var countdownSeconds = 0; var score = 0; var lives = BrickBreakerModel.startingLives; var isOver = false; var best = 0; var isNewBest = false }`.
  - `@MainActor @Observable final class BrickBreakerGame` with `init(model: BrickBreakerModel = .init(), stats: StatsStore = .shared)`, `private(set) var display`, `@ObservationIgnored private(set) var model`, `var isPaused { get set }`, `var countdown: TimeInterval`, `func tick(now: Date)`, `func reset()`, `func aim(atCourtX x: CGFloat)`, `func nudge(by dx: CGFloat)`, `func pointerMoved(toCourtX x: CGFloat?, insidePanel: Bool)` (same pause rules as `PongGame.pointerMoved`), `@ObservationIgnored private(set) var ballTrail`, `private(set) var lastWallHit: WallHit?`, `private(set) var lastBrickHit: WallHit?` (brick center, inward `(0, 1)`, for a spark), `@ObservationIgnored private(set) var rowSlide: CGFloat` (1 right after a drop, easing to 0 over 0.25 s, for the view).

Behaviour: a row timer and a survival-point timer advance only on `.playing` steps. When the row timer passes `model.rowInterval`, call `model.dropRow()` and reset the timer. Every whole second of play adds 1 survival point. After `model.lostBall`, start a countdown (`clock.startCountdown()`). When `model.isOver` first becomes true, call `stats.recordScore(model.score, for: .brickBreaker)` once and put the result in `display.isNewBest`. `display.best` reads `stats.stats.bestScore(for: .brickBreaker)`.

- [ ] **Step 1: Write the failing tests:**
  - `rowsDropOnlyWhilePlaying`: unpause, tick through the countdown, then tick 10.1 s of play in `1/60` steps: `rowsDropped == 1`. Pause, tick 30 s more: still 1.
  - `survivalPointsCountOnlyPlayTime`: after 5 s of play the score has 5 survival points (use a model with no bricks hit, for example by keeping the ball away from the wall with a test `init(model:)` that starts the ball moving sideways near the paddle); 10 s paused adds nothing.
  - `losingABallStartsACountdown`: a model whose ball is just below the paddle moving down: one play tick, then `display.lives == 2` and `display.countdownSeconds == 3`.
  - `runOverRecordsTheBestScoreOnce`: a model on its last life, ball about to be missed: tick twice; `display.isOver`, `display.isNewBest` with a fresh `StatsStore(defaults:)`, and the store's best equals the score. A second run with a lower score gives `isNewBest == false`.
  - `displayChangesOnlyOnEvents`: wrap a few play ticks with no point, row or life change in `withObservationTracking({ _ = game.display }, onChange: { changed = true })` and expect `changed == false`.
- [ ] **Step 2: Run.** Expected: compile failure.
- [ ] **Step 3: Implement** following `PongGame` and `AirHockeyGame` (clock, `publishDisplay()`, trail kept for `PongGame.trailLength`, cleared on a lost ball and on reset).
- [ ] **Step 4: Run tests and lint.** Expected: pass.
- [ ] **Step 5: Commit** `feat: add the brick breaker game loop`.

---

### Task 6: The view, the game-over screen and wiring

**Files:**
- Create: `NotchPong/BrickBreaker/BrickBreakerView.swift`, `NotchPong/BrickBreaker/LivesView.swift`, `NotchPong/Match/RunResult.swift`
- Modify: `NotchPong/Match/GameView.swift`, `NotchPong/Match/MatchMessageView.swift`, `NotchPong/Pong/PongView.swift`, `NotchPong/AirHockey/AirHockeyView.swift`
- Test: none new (drawing). Existing tests must still pass.

**Interfaces:**
- Consumes: `BrickBreakerGame`, `BrickBreakerDisplay`, `CourtLayout`, `CourtEffects.glow/drawTrail/drawEvents`, `ScoreNumber`, `ScoreLabel`, `MatchCountdownView`, `MatchControlsView`.
- Produces: `nonisolated struct RunResult: Equatable { let score: Int; let best: Int; let isNewBest: Bool }`, and `MatchMessageView` gains `runResult: RunResult? = nil`. When it's non-nil it shows "game over", the score, "new best" or "best N", and "play again", in place of the winner block. Pong and Air Hockey callers don't change.

- [ ] **Step 1: Build `BrickBreakerView(state: PanelState)`** in the style of `PongView`: `@State private var game = BrickBreakerGame()`, `TimelineView(.animation(paused: game.display.isPaused))` + `Canvas` drawing the wall (each brick a rounded rect in `Palette.ball`, the whole wall offset up by `game.rowSlide * (rowHeight + gap)` scaled), the paddle with `CourtEffects.glow` in `Palette.paddle`, the trail and the ball as in `PongView`, and sparks for `game.lastWallHit` and `game.lastBrickHit` with `CourtEffects.drawWallSpark`. `drawWallSpark` and `drawExplosion` scale by Pong's 1.6 court width (`CourtEffects.swift:52`, `:75`); give them a `courtWidth: CGFloat = PongModel.courtSize.width` parameter the same way as `courtPoint`. Map court units with `CourtLayout.rect(in:)` and scale `court.width / BrickBreakerModel.courtSize.width`. Pointer x goes through `CourtLayout.courtPoint(forPanelPoint:in:)`; note that function assumes Pong's 1.6 width, so add a `courtWidth: CGFloat` parameter to it (default `PongModel.courtSize.width`) rather than duplicating it. Keys: left/right arrows and A/D call `game.nudge(by: ∓0.06)` and unpause, as Pong does.
- [ ] **Step 2: HUD overlay.** At the top centre: `ScoreNumber(value: display.score)` with `LivesView(lives: display.lives)` (3 small teal circles, filled for lives left, outlined for lost) on one side and `ScoreLabel(text: "best \(display.best)")` on the other. Then the existing `MatchCountdownView` and `MatchMessageView(... runResult: display.isOver ? RunResult(...) : nil)` overlays, laid out as in `PongView`.
- [ ] **Step 3: Wire it in.** `GameView` shows `BrickBreakerView(state:)` for `.brickBreaker`. Add `#Preview`s for `BrickBreakerView`, `LivesView` and a game-over `MatchMessageView`.
- [ ] **Step 4: Run tests and lint.** Expected: all pass, lint silent.
- [ ] **Step 5: Manual check** (build, launch the app, pick brick breaker in Settings), and tune constants in `BrickBreakerModel` if needed:
  - the panel opens portrait at small, medium and large, and switching games while open resizes it;
  - at the small size the drop under the notch looks right and never spreads past the notch in the menu bar;
  - the first minute is relaxed, the game visibly speeds up after a few levels;
  - pause by leaving the panel, by opening Settings and by closing the panel; the run resumes where it was with a countdown;
  - losing all lives and letting the wall reach the paddle both show "game over" with the right best score;
  - Pong and Air Hockey still open at their wide shape and play as before.
- [ ] **Step 6: Commit** `feat: add brick breaker`.

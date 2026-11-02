# NotchPong v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A menu-bar-only macOS app where dragging down from the notch grows a neon Pong panel (sized by the pull, between min and max), played against a computer opponent and closed by pushing it back up.

**Architecture:** Pure, unit-tested Swift value types hold all logic: notch geometry, pull-to-size mapping and release decisions, Pong physics, and the computer opponent. A thin `@MainActor` AppKit layer owns two borderless, non-activating `NSPanel`s. One is an invisible trigger over the notch. The other is the game panel, whose frame follows the drag. Both host SwiftUI views. SwiftUI renders the game with `TimelineView(.animation)` + `Canvas`.

**Tech Stack:** Swift 6, SwiftUI, AppKit (`NSPanel` only), Swift Testing, Xcode 27, macOS 26 deployment target. No third-party dependencies.

**Spec:** `docs/superpowers/specs/2026-11-02-notchpong-design.md`

## Global Constraints

- Deployment target macOS 26.0. Swift 6 language mode, strict concurrency. Every `@Observable` class is `@MainActor`.
- No third-party frameworks. AppKit only for `NSPanel`/`NSScreen`/`NSEvent` work that SwiftUI can't do.
- App Sandbox ON. No Accessibility, Input Monitoring or Screen Recording, and no `NSEvent.addGlobalMonitorForEvents`.
- `LSUIElement = YES` (no Dock icon). `MenuBarExtra` with "Play Pong" and "Quit NotchPong".
- Panel colors: background `#000000`, paddles `#4dfcc4` with glow, ball `#ff4fa3` with glow, dashed center line, faint teal outline glow, all corners rounded (continuous, 28 pt), handle bar at bottom center.
- In the menu bar band, the panel is exactly notch-width. It must never cover menu bar items.
- Size: body min 400×250 pt, max 736×460 pt (raised from 640×400 by user request) (court ratio 1.6:1). These are the builder's conversion of the mockup's "short pull" and "medium pull" and are tunable constants.
- First to 5 points wins. One computer difficulty. No sound.
- Follow `~/.claude/CLAUDE.md` (`foregroundStyle`, `Button` instead of `onTapGesture`, `Task.sleep(for:)`, one type per file, and so on).
- SwiftLint is installed at `/opt/homebrew/bin/swiftlint`. `swiftlint` must report no errors before each commit.

## Review Focus

1. **A big time step after sleep, pause or a hidden panel**: `TimelineView` can deliver a dt of several seconds, and the ball must not teleport or tunnel. Clamp dt to 1/30 s (test in Task 4).
2. **A fast ball crossing a paddle in one frame**: it must still bounce. Use a swept check on the paddle's x-plane, not an overlap test (test in Task 4).
3. **A drag that goes up past where it started, or ends with a tiny pull**: the size never goes negative and the panel closes cleanly (test in Task 2).
4. **Displays change** (lid closed, external monitor only, resolution change): the trigger panel moves or hides itself, and on a screen with no notch there's no trigger strip at all (test for nil geometry in Task 1, handling in Task 3).
5. **Closing mid-rally and reopening**: the old ball state must not leak, and the new panel shows 0–0 with a fresh serve (test in Task 6).

## File Structure

```
NotchPong/
  NotchPong.xcodeproj
  NotchPong/
    App/
      NotchPongApp.swift          @main, MenuBarExtra, delegate adaptor
      AppDelegate.swift           creates NotchPanelController at launch
      Palette.swift               neon colors (Color constants)
    NotchPanel/
      NotchGeometry.swift         pure: notch rect + menu bar height from screen values
      PullSizing.swift            pure: drag distance → body size, release outcome
      PanelPhase.swift            enum closed / dragging / open
      PanelState.swift            @Observable @MainActor: phase, bodySize, matchID
      NotchPanel.swift            NSPanel subclass (borderless, non-activating, can become key)
      NotchPanelController.swift  @MainActor: owns trigger + game panels, frames, screen changes
      TriggerView.swift           invisible view on the notch, open DragGesture
      GamePanelView.swift         neck + body shape, hosts PongView, handle close DragGesture
      NotchShape.swift            Shape: notch-width neck + rounded body
    Pong/
      PongModel.swift             pure struct: court, ball, paddles, score, step(dt:)
      Ball.swift                  struct
      PongSide.swift              enum player / computer
      ComputerOpponent.swift      pure struct: paddle tracking with speed cap + reaction delay
      PongGame.swift              @Observable @MainActor wrapper: model, paused, tick(date:)
      PongView.swift              TimelineView + Canvas renderer, hover + keys input
  NotchPongTests/
    NotchGeometryTests.swift
    PullSizingTests.swift
    PongModelTests.swift
    ComputerOpponentTests.swift
    PongGameTests.swift
```

Test command used throughout:
`xcodebuild test -project NotchPong.xcodeproj -scheme NotchPong -destination 'platform=macOS' -quiet`

---

### Task 1: Project, menu bar app shell, notch geometry

**Files:**
- Create: Xcode project (macOS App, SwiftUI, Swift Testing) at the repo root, named `NotchPong`. Use the Xcode MCP `XcodeNewProject` or Xcode > New Project.
- Create: `NotchPong/App/NotchPongApp.swift`, `NotchPong/App/AppDelegate.swift`, `NotchPong/App/Palette.swift`, `NotchPong/NotchPanel/NotchGeometry.swift`
- Test: `NotchPongTests/NotchGeometryTests.swift`

**Interfaces:**
- Produces:
  - `struct NotchGeometry: Equatable { let notchRect: CGRect; let menuBarHeight: CGFloat }` (screen coordinates, origin bottom-left as in AppKit)
  - `static func NotchGeometry.make(screenFrame: CGRect, safeAreaTop: CGFloat, auxiliaryTopLeft: CGRect?, auxiliaryTopRight: CGRect?) -> NotchGeometry?`, which returns `nil` when `safeAreaTop == 0` or either auxiliary rect is nil (no notch)
  - `extension NotchGeometry { static func forScreen(_ screen: NSScreen) -> NotchGeometry? }`, which passes `screen.frame`, `safeAreaInsets.top`, `auxiliaryTopLeftArea` and `auxiliaryTopRightArea` to `make`
  - `enum Palette { static let background, paddle, ball: Color }` with the hex values from Global Constraints

- [ ] **Step 1: Create the project.** Set the deployment target to macOS 26.0 and Swift 6. Delete the template `ContentView.swift`. Set Info.plist `LSUIElement` = YES (Application is agent). Keep App Sandbox on (template default). Make sure the test target is Swift Testing. Create the `App/`, `NotchPanel/` and `Pong/` groups.
- [ ] **Step 2: Write the failing tests** in `NotchGeometryTests.swift`:

```swift
@Test func notchRectSitsBetweenAuxiliaryAreas() {
    let g = NotchGeometry.make(
        screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        safeAreaTop: 32,
        auxiliaryTopLeft: CGRect(x: 0, y: 950, width: 661, height: 32),
        auxiliaryTopRight: CGRect(x: 851, y: 950, width: 661, height: 32))
    #expect(g == NotchGeometry(notchRect: CGRect(x: 661, y: 950, width: 190, height: 32), menuBarHeight: 32))
}

@Test func noNotchReturnsNil() {
    #expect(NotchGeometry.make(screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
                               safeAreaTop: 0, auxiliaryTopLeft: nil, auxiliaryTopRight: nil) == nil)
}

@Test func offsetScreenKeepsNotchInScreenCoordinates() {
    // second display placed to the right of the main one
    let g = NotchGeometry.make(
        screenFrame: CGRect(x: 1920, y: 0, width: 1512, height: 982), safeAreaTop: 32,
        auxiliaryTopLeft: CGRect(x: 1920, y: 950, width: 661, height: 32),
        auxiliaryTopRight: CGRect(x: 2771, y: 950, width: 661, height: 32))
    #expect(g?.notchRect.minX == 2581)
}
```

- [ ] **Step 3: Run the tests and confirm they fail** (`NotchGeometry` doesn't exist yet).
- [ ] **Step 4: Implement `NotchGeometry`** as specified: `notchRect.minX = auxLeft.maxX`, `width = auxRight.minX - auxLeft.maxX`, `y = screenFrame.maxY - safeAreaTop`, `height = safeAreaTop`.
- [ ] **Step 5: Implement the app shell.** `NotchPongApp` has `@NSApplicationDelegateAdaptor(AppDelegate.self)` and `MenuBarExtra("NotchPong", systemImage: "gamecontroller")`, containing `Button("Play Pong") { … }` (a no-op for now, wired up in Task 3), a `Divider()`, and `Button("Quit NotchPong") { NSApplication.shared.terminate(nil) }` with `.keyboardShortcut("q")`. `AppDelegate` is `@MainActor final class AppDelegate: NSObject, NSApplicationDelegate`, with an empty `applicationDidFinishLaunching` for now.
- [ ] **Step 6: Run the tests and confirm they pass. Build and run:** there's no Dock icon, the gamecontroller icon shows in the menu bar, and Quit works.
- [ ] **Step 7: Run `swiftlint`, then commit:** `git add -A && git commit -m "feat: menu bar app shell and notch geometry"`

---

### Task 2: Pull sizing and release decisions

**Files:**
- Create: `NotchPong/NotchPanel/PullSizing.swift`
- Test: `NotchPongTests/PullSizingTests.swift`

**Interfaces:**
- Produces:
  - `enum PullSizing` with `static let aspect: CGFloat = 1.6`, `static let minBodyHeight: CGFloat = 250`, `static let maxBodyHeight: CGFloat = 400`, `static let flickVelocity: CGFloat = 800` (pt/s upward)
  - `static func bodySize(forPull pull: CGFloat) -> CGSize`, where height = `clamp(pull, 0, maxBodyHeight)` and width = `height * aspect`. Below min, it's allowed to be smaller than min so the panel can visibly grow.
  - `enum ReleaseOutcome: Equatable { case close; case open(CGSize) }`
  - `static func releaseOutcome(pull: CGFloat, upwardVelocity: CGFloat) -> ReleaseOutcome`, which returns `.close` if `pull < minBodyHeight` or `upwardVelocity > flickVelocity`, and otherwise `.open(bodySize(forPull: pull))`. Used for both opening and closing drags. For a closing drag, the caller passes `pull = currentHeight - upwardTranslation`.

- [ ] **Step 1: Write the failing tests:**

```swift
@Test func pullMapsToCourtAspect() { #expect(PullSizing.bodySize(forPull: 300) == CGSize(width: 480, height: 300)) }
@Test func pullClampsAtMax() { #expect(PullSizing.bodySize(forPull: 900) == CGSize(width: 640, height: 400)) }
@Test func negativePullIsZero() { #expect(PullSizing.bodySize(forPull: -50) == .zero) }
@Test func releaseBelowMinCloses() { #expect(PullSizing.releaseOutcome(pull: 249, upwardVelocity: 0) == .close) }
@Test func releaseAtMinOpensAtMin() { #expect(PullSizing.releaseOutcome(pull: 250, upwardVelocity: 0) == .open(CGSize(width: 400, height: 250))) }
@Test func releasePastMaxOpensAtMax() { #expect(PullSizing.releaseOutcome(pull: 700, upwardVelocity: 0) == .open(CGSize(width: 640, height: 400))) }
@Test func upwardFlickClosesEvenWhenLarge() { #expect(PullSizing.releaseOutcome(pull: 380, upwardVelocity: 1200) == .close) }
```

- [ ] **Step 2: Run the tests and confirm they fail.**
- [ ] **Step 3: Implement `PullSizing` and `ReleaseOutcome`** in `PullSizing.swift` (one file is fine, because `ReleaseOutcome` exists only as this API's return type).
- [ ] **Step 4: Run the tests and confirm they pass.**
- [ ] **Step 5: Run `swiftlint`, then commit:** `feat: pull-to-size mapping and release rules`

---

### Task 3: Notch panels: pull open, push closed, Play Pong menu item

This is the riskiest task. Check panel level and click handling on a real notched Mac before polishing anything.

**Files:**
- Create: `NotchPong/NotchPanel/PanelPhase.swift`, `PanelState.swift`, `NotchPanel.swift`, `NotchPanelController.swift`, `TriggerView.swift`, `GamePanelView.swift`, `NotchShape.swift`
- Modify: `NotchPong/App/AppDelegate.swift` and `NotchPong/App/NotchPongApp.swift` (wire up "Play Pong")

**Interfaces:**
- Consumes: `NotchGeometry.forScreen(_:)`, `PullSizing.bodySize(forPull:)`, `PullSizing.releaseOutcome(pull:upwardVelocity:)`, `ReleaseOutcome`
- Produces:
  - `enum PanelPhase: Equatable { case closed, dragging, open }`
  - `@Observable @MainActor final class PanelState { var phase: PanelPhase = .closed; var bodySize: CGSize = .zero; private(set) var matchID = UUID(); func startNewMatch() }`. Task 6 uses `matchID` to reset the game on each open.
  - `final class NotchPanel: NSPanel` with `init(contentRect:)` using style `[.borderless, .nonactivatingPanel]`, `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false`, `level = .statusBar`, `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`, and `override var canBecomeKey: Bool { true }`
  - `@MainActor final class NotchPanelController { init(state: PanelState); func start(); func playFromMenu(); func updatePull(_ pull: CGFloat); func endPull(pull: CGFloat, upwardVelocity: CGFloat) }`. `updatePull` sets `phase = .dragging` and `bodySize = PullSizing.bodySize(forPull:)` and resizes the panel. `endPull` applies `releaseOutcome`.
  - `AppDelegate` exposes `let panelState = PanelState()` and `private(set) var controller: NotchPanelController?`. The MenuBarExtra "Play Pong" button calls `appDelegate.controller?.playFromMenu()`.
  - `struct NotchShape: Shape { var neckWidth: CGFloat; var neckHeight: CGFloat; var bodyCornerRadius: CGFloat = 22 }`, a neck centered at the top, full width below `neckHeight`, rounded bottom corners

- [ ] **Step 1: Implement `PanelPhase`, `PanelState`, `NotchPanel` and `NotchShape`** as specified above.
- [ ] **Step 2: Implement `NotchPanelController`.**
  - `start()`: picks the screen where `NotchGeometry.forScreen` is non-nil (prefer `NSScreen.screens` order). If there is one, it creates the trigger `NotchPanel` exactly over `notchRect`, hosting `TriggerView`. It also creates (hidden) the game `NotchPanel`, hosting `GamePanelView`. It observes `NSApplication.didChangeScreenParametersNotification` (async sequence via `NotificationCenter.default.notifications(named:)` in a `Task`) and re-runs the placement, hiding the trigger when there's no notch.
  - Game panel frame for a given `bodySize`: width `max(bodySize.width, neckWidth)`, height `menuBarHeight + bodySize.height`, horizontally centered on the notch, top edge = screen `maxY`. Use `setFrame(_:display:)` while dragging. When snapping, animate with `NSAnimationContext.runAnimationGroup` (0.2 s) to the open size, or down to neck-only and then `orderOut`.
  - `playFromMenu()`: if there's a notch, it uses it. If not, it uses `NSScreen.main`, a 190-pt-wide virtual neck centered at the top, and the menu bar height from `screen.frame.maxY - screen.visibleFrame.maxY`. It opens straight to the max size with the snap animation and calls `state.startNewMatch()`.
  - Opening from a drag also calls `state.startNewMatch()` when the release result is `.open`. Show the game panel with `orderFrontRegardless()` and `makeKey()` so keys work without activating the app.
- [ ] **Step 3: Implement `TriggerView`**: `Color.clear.contentShape(.rect)` with `DragGesture(minimumDistance: 2, coordinateSpace: .global)`. `onChanged` → controller `updatePull(translation.height)`. `onEnded` → controller `endPull(pull: translation.height, upwardVelocity: -velocity.height)`. Pass the controller in as closures `onPull: (CGFloat) -> Void`, `onRelease: (CGFloat, CGFloat) -> Void`, not a reference. `TriggerView` has `.accessibilityLabel("Pull down to play Pong")`.
- [ ] **Step 4: Implement `GamePanelView`**: `NotchShape` filled with `Palette.background`, a teal 1-pt stroke at 0.33 opacity and a teal shadow with radius 15. Inside, below the neck, put `Color.clear` (Task 6 swaps in `PongView`). At the bottom center there's a 30×4 capsule handle at 0.4 opacity. Its `DragGesture` reports `pull = state.bodySize.height + translation.height` to the same controller pull and release closures, so dragging up shrinks the panel and releasing below min or flicking up closes it. Give the handle `.accessibilityLabel("Close")` and `.accessibilityAction { onClose() }`.
- [ ] **Step 5: Manual check on a notched Mac (record the results in the commit message body):**
  - The trigger panel sits over the notch, and clicking menu items left and right of the notch still works.
  - Dragging down grows the neon panel live. Releasing below 250 pt of pull closes it, and releasing above it stays open at that size, capped at 640×400.
  - Dragging the handle up closes it, and a quick upward flick from max size closes it.
  - In the menu bar band, the panel is notch-width only.
  - "Play Pong" from the menu opens at max size. With an external display only (lid closed), "Play Pong" still works and nothing covers menu items.
  - If `.statusBar` level draws under the menu bar, try `NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 1)` and note it.
- [ ] **Step 6: Run `swiftlint`, then commit:** `feat: notch trigger and pull-open game panel`

---

### Task 4: Pong physics model

**Files:**
- Create: `NotchPong/Pong/PongModel.swift`, `NotchPong/Pong/Ball.swift`, `NotchPong/Pong/PongSide.swift`
- Test: `NotchPongTests/PongModelTests.swift`

**Interfaces:**
- Produces (court units: width 1.6, height 1.0, origin top-left, y down):
  - `enum PongSide: Equatable { case player, computer }`. The player is the right paddle, the computer the left.
  - `struct Ball: Equatable { var position: CGPoint; var velocity: CGVector }`
  - `struct PongModel` with constants `courtSize = CGSize(width: 1.6, height: 1.0)`, `paddleHeight: CGFloat = 0.22`, `paddleInset: CGFloat = 0.04` (paddle x-plane from each side), `ballRadius: CGFloat = 0.012`, `serveSpeed: CGFloat = 0.9`, `speedUpPerHit: CGFloat = 1.05`, `maxSpeed: CGFloat = 2.0`, `winningScore = 5`, `maxStep: TimeInterval = 1.0 / 30`
  - State: `var ball: Ball`, `var playerY: CGFloat`, `var computerY: CGFloat` (paddle centers), `private(set) var playerScore = 0`, `private(set) var computerScore = 0`, `private(set) var winner: PongSide?`
  - `init(serveToward: PongSide = .player, serveAngle: CGFloat = 0.3)`, which puts the ball at the center, with velocity of `serveSpeed` toward that side at `serveAngle` radians
  - `mutating func step(dt: TimeInterval)`, which clamps dt to `maxStep`, then moves the ball, bounces it off the top and bottom walls, does a swept paddle bounce on each paddle's x-plane, and scores when the ball passes x < 0 or x > 1.6. After a point it re-serves toward the side that conceded. It does nothing once `winner != nil`.
  - Paddle bounce: reflect vx, multiply speed by `speedUpPerHit` up to `maxSpeed`, and set the exit angle from the hit offset `(ballY - paddleY) / (paddleHeight / 2)`, mapped to ±60°.

- [ ] **Step 1: Write the failing tests:**

```swift
@Test func ballBouncesOffTopWall() {
    var m = PongModel(); m.ball = Ball(position: CGPoint(x: 0.8, y: 0.013), velocity: CGVector(dx: 0, dy: -1))
    m.step(dt: 0.01); #expect(m.ball.velocity.dy > 0)
}
@Test func playerPaddleReturnsBall() {
    var m = PongModel(); m.playerY = 0.5
    m.ball = Ball(position: CGPoint(x: 1.55, y: 0.5), velocity: CGVector(dx: 1, dy: 0))
    m.step(dt: 0.02); #expect(m.ball.velocity.dx < 0)
}
@Test func fastBallDoesNotTunnelThroughPaddle() {
    var m = PongModel(); m.playerY = 0.5
    m.ball = Ball(position: CGPoint(x: 1.50, y: 0.5), velocity: CGVector(dx: 2.0, dy: 0))
    m.step(dt: 1.0 / 30); #expect(m.ball.velocity.dx < 0)
}
@Test func missScoresForComputer() {
    var m = PongModel(); m.playerY = 0.1
    m.ball = Ball(position: CGPoint(x: 1.59, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
    m.step(dt: 0.03); #expect(m.computerScore == 1)
    #expect(abs(m.ball.position.x - 0.8) < 0.05)
}
@Test func hugeDtIsClamped() {
    var m = PongModel(); let start = m.ball.position
    m.step(dt: 5); #expect(abs(m.ball.position.x - start.x) <= m.serveSpeed / 30 + 0.0001)
}
@Test func fifthPointWinsAndFreezes() {
    var m = PongModel()
    for _ in 0..<5 { m.playerY = 0.1; m.computerY = 0.1
        m.ball = Ball(position: CGPoint(x: 0.01, y: 0.9), velocity: CGVector(dx: -1, dy: 0)); m.step(dt: 0.03) }
    #expect(m.winner == .player)
    let frozen = m.ball; m.step(dt: 0.03); #expect(m.ball == frozen)
}
@Test func speedCapsAtMax() {
    var m = PongModel(); m.playerY = 0.5
    m.ball = Ball(position: CGPoint(x: 1.55, y: 0.5), velocity: CGVector(dx: 1.99, dy: 0))
    m.step(dt: 0.02); #expect(hypot(m.ball.velocity.dx, m.ball.velocity.dy) <= 2.0 + 0.0001)
}
```

- [ ] **Step 2: Run the tests and confirm they fail.**
- [ ] **Step 3: Implement `PongSide`, `Ball` and `PongModel`** as specified. For the swept paddle check: if the ball's x crosses the paddle plane during this step, find y at the crossing time and test it against the paddle's span plus `ballRadius`.
- [ ] **Step 4: Run the tests and confirm they pass.**
- [ ] **Step 5: Run `swiftlint`, then commit:** `feat: pong physics model`

---

### Task 5: Computer opponent

**Files:**
- Create: `NotchPong/Pong/ComputerOpponent.swift`
- Test: `NotchPongTests/ComputerOpponentTests.swift`

**Interfaces:**
- Consumes: `Ball`, `PongModel.paddleHeight`, `PongModel.courtSize`
- Produces: `struct ComputerOpponent { var maxSpeed: CGFloat = 0.75; var reactionDelay: TimeInterval = 0.12; var deadZone: CGFloat = 0.02; mutating func nextPaddleY(current: CGFloat, ball: Ball, dt: TimeInterval) -> CGFloat }`
  - Behavior: it remembers the ball y from `reactionDelay` seconds ago (a small ring buffer of `(elapsed, y)` samples). It uses the newest sample at least `reactionDelay` old, and if none is that old yet, the oldest sample it has. and moves toward it at up to `maxSpeed * dt`. When the ball is moving away (`velocity.dx > 0`), it drifts toward 0.5 instead. It doesn't move if it's within `deadZone`. The result is clamped so the paddle stays inside the court.

- [ ] **Step 1: Write the failing tests:**

```swift
@Test func movesTowardIncomingBallButNoFasterThanMax() {
    var ai = ComputerOpponent(reactionDelay: 0)
    let ball = Ball(position: CGPoint(x: 0.5, y: 0.9), velocity: CGVector(dx: -1, dy: 0))
    let y = ai.nextPaddleY(current: 0.5, ball: ball, dt: 0.1)
    #expect(y > 0.5); #expect(y - 0.5 <= 0.075 + 0.0001)
}
@Test func returnsToCenterWhenBallMovesAway() {
    var ai = ComputerOpponent(reactionDelay: 0)
    let ball = Ball(position: CGPoint(x: 0.5, y: 0.9), velocity: CGVector(dx: 1, dy: 0))
    #expect(ai.nextPaddleY(current: 0.2, ball: ball, dt: 0.1) > 0.2)
}
@Test func staysInsideCourt() {
    var ai = ComputerOpponent(maxSpeed: 100, reactionDelay: 0)
    let ball = Ball(position: CGPoint(x: 0.5, y: 1.0), velocity: CGVector(dx: -1, dy: 0))
    #expect(ai.nextPaddleY(current: 0.5, ball: ball, dt: 1) <= 1.0 - 0.11)
}
@Test func reactsToDelayedBallPosition() {
    var ai = ComputerOpponent(maxSpeed: 100, reactionDelay: 0.2, deadZone: 0)
    let low = Ball(position: CGPoint(x: 0.5, y: 0.2), velocity: CGVector(dx: -1, dy: 0))
    _ = ai.nextPaddleY(current: 0.5, ball: low, dt: 0.1)
    let high = Ball(position: CGPoint(x: 0.5, y: 0.8), velocity: CGVector(dx: -1, dy: 0))
    #expect(ai.nextPaddleY(current: 0.5, ball: high, dt: 0.05) < 0.5) // still chasing the old, lower sample
}
```

- [ ] **Step 2: Run the tests and confirm they fail.**
- [ ] **Step 3: Implement `ComputerOpponent`** as specified.
- [ ] **Step 4: Run the tests and confirm they pass.**
- [ ] **Step 5: Run `swiftlint`, then commit:** `feat: beatable computer opponent`

---

### Task 6: Game loop, rendering, controls, pause, fresh match per open

**Files:**
- Create: `NotchPong/Pong/PongGame.swift`, `NotchPong/Pong/PongView.swift`
- Modify: `NotchPong/NotchPanel/GamePanelView.swift` (swap `Color.clear` for `PongView`)
- Test: `NotchPongTests/PongGameTests.swift`

**Interfaces:**
- Consumes: `PongModel`, `ComputerOpponent`, `PanelState.matchID`, `Palette`
- Produces: `@Observable @MainActor final class PongGame { private(set) var model = PongModel(); var isPaused = true; func reset(); func tick(now: Date); func setPlayerPaddle(y: CGFloat); func nudgePlayerPaddle(by: CGFloat) }`
  - `tick(now:)`: while paused, it clears the stored last-tick time and returns. When not paused and there's no last-tick time, it stores `now` and returns without stepping. Otherwise dt = now − last tick. `reset()` also clears the last-tick time. When not paused, it runs the computer and then `model.step`.
  - `setPlayerPaddle(y:)` clamps the y-coordinate (court units) so the paddle stays inside. `nudgePlayerPaddle(by:)` calls it with `playerY + delta`.

- [ ] **Step 1: Write the failing tests:**

```swift
@MainActor @Test func pausedGameDoesNotAdvance() {
    let g = PongGame(); g.isPaused = true
    let start = g.model.ball; let t = Date.now
    g.tick(now: t); g.tick(now: t.addingTimeInterval(0.5)); #expect(g.model.ball == start)
}
@MainActor @Test func firstTickAfterUnpauseDoesNotJump() {
    let g = PongGame(); let t = Date.now
    g.tick(now: t); g.isPaused = false
    g.tick(now: t.addingTimeInterval(10)); let afterFirst = g.model.ball
    #expect(abs(afterFirst.position.x - 0.8) < 0.001)
}
@MainActor @Test func resetStartsFreshMatch() {
    let g = PongGame(); g.isPaused = false; let t = Date.now
    for i in 0..<200 { g.tick(now: t.addingTimeInterval(Double(i) / 60)) }
    g.reset()
    #expect(g.model.playerScore == 0 && g.model.computerScore == 0 && g.model.winner == nil)
    #expect(abs(g.model.ball.position.x - 0.8) < 0.001); #expect(g.isPaused)
}
@MainActor @Test func playerPaddleClampsInsideCourt() {
    let g = PongGame(); g.setPlayerPaddle(y: 2); #expect(g.model.playerY <= 1.0 - 0.11)
}
```

- [ ] **Step 2: Run the tests and confirm they fail.**
- [ ] **Step 3: Implement `PongGame`** as specified.
- [ ] **Step 4: Implement `PongView`.**
  - Draw `TimelineView(.animation(paused: game.isPaused))` + `Canvas`, scaling court units to the view size. It draws the dashed center line (teal, 0.35 opacity), paddles (`Palette.paddle`, 5-pt-wide rounded rects with an `addFilter(.shadow(color: Palette.paddle, radius: 8))` layer), the ball (`Palette.ball`, also glowing), and the score as monospaced text at the top (`.font(.system(.headline, design: .monospaced))`). Call `game.tick(now:)` from the timeline date via `.onChange(of: context.date)` or inside the canvas closure.
  - Pointer: `.onContinuousHover`. `.active(location)` → `setPlayerPaddle(y: location.y / height)` and `isPaused = false`. `.ended` → `isPaused = true`.
  - Keys: make the view `.focusable()`, focused on appear. `.onKeyPress` for up/down arrows and w/s nudges by 0.06.
  - When paused and no winner, overlay "Move here to play" (`.secondary`). When there's a winner, overlay "You win" or "Computer wins" with a `Button("Play again") { game.reset() }`.
  - Add `.accessibilityElement(children: .ignore)`, `.accessibilityLabel("Pong")` and `.accessibilityValue("You \(playerScore), computer \(computerScore)")`.
- [ ] **Step 5: Wire it into `GamePanelView`**: own a `@State private var game = PongGame()` and call `.onChange(of: state.matchID) { game.reset() }` (the zero-parameter variant). Also call `game.reset()` and set `isPaused = true` when `state.phase` becomes `.closed`.
- [ ] **Step 6: Run the tests and confirm they all pass.**
- [ ] **Step 7: Manual check:** pull the panel open and play. The paddle follows the pointer, the computer is beatable but not trivial, moving off the court pauses the game, and the arrow keys work. Close mid-rally and reopen, and it shows 0–0. Win to 5, see the message, and "Play again" works.
- [ ] **Step 8: Run `swiftlint`, then commit:** `feat: playable neon pong in the notch panel`

---

### Task 7: App Store readiness pass

**Files:**
- Modify: project settings, `Assets.xcassets` (app icon placeholder), Info.plist

- [ ] **Step 1:** In Signing & Capabilities, confirm App Sandbox is the only capability, with no extra entitlements. Set `LSApplicationCategoryType` = `public.app-category.games` and a bundle ID like `com.filippocilia.NotchPong`.
- [ ] **Step 2:** Add a simple app icon (placeholder is fine). App Review needs one before submission.
- [ ] **Step 3:** Run the full test command and `swiftlint`. Both must be clean.
- [ ] **Step 4:** Product › Archive, then Validate App in the Organizer, which should report no errors. Note any warnings in the commit body.
- [ ] **Step 5: Commit:** `chore: app store readiness`

---

## v1.1 (built 2026-11-02 on feat/v1.1)

These each get their own spec/plan pass when started. They're listed here so v1 code leaves room for them, not built now.

1. **Air hockey:** a second game that reuses `Ball` and the swept-collision approach. A game picker in the panel (or the menu).
2. **Two-player mode:** built locally (second player on W/S), then removed. Multiplayer will instead run between two Macs over the network (MultipeerConnectivity), with its own spec when started.
3. **Saved scores:** persist wins and losses (and the best streak) with `@AppStorage` or SwiftData, shown in the panel.
4. **Settings window:** difficulty picker done early (Easy/Moderate/Hard/Expert, Moderate default). Still to add: default panel size, launch at login (`SMAppService`) and the game picker.

---

## v1.2: more games (planned 2026-11-02, not started)

Quick games for the notch: some last a few minutes, some only seconds. Each game has one main input, and the others are extras: keys come first for keyboard games, the pointer for pointer games. Each game is a new `GameKind` case shown by `GameView`, with its own `<Name>Game` (`@MainActor @Observable`) and `<Name>View`, in the same style as Pong and air hockey. They should reuse `MatchClock`, `MatchCountdownView`, `MatchMessageView` and `CourtEffects` where they fit. Each one gets its own spec/plan pass when it's started.

1. **Snake:** arrows or WASD (main input). Lasts a few minutes. Grid-based, and the snake speeds up as it grows. The pointer isn't a priority.
2. **Brick breaker:** pointer (main input), arrows as extras. Lasts a few minutes. A paddle along the bottom knocks out a wall of bricks. Reuses `Ball`, the swept-collision bounces and the wall sparks. Cheapest to build.
3. **Runner:** space or up arrow to jump. Lasts seconds to a minute. Obstacles scroll in from the right, the panel's width gives room to react, and one hit ends the run.
4. **Target tap:** pointer clicks. A 30-second round. Glowing dots pop up and fade, and you click as many as you can.

Open questions for the specs:
- Records: `PlayerStats` only tracks wins and losses against the computer. These games are score-based, so they probably need a best score per game.
- Pausing: Pong pauses when the pointer leaves the panel. Keyboard games may want to pause on lost focus instead.
- Suggested order: Snake, then the runner, then brick breaker, then target tap. That's Claude's call, not yet confirmed.

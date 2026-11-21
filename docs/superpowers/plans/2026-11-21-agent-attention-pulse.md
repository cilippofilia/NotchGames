# Agent Attention Pulse Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `open -g notchgames://attention` makes the notch (closed) or the panel outline (open) pulse until the pointer moves onto it.

**Architecture:** A small value type `AttentionSignal` holds the on/off state and the "pointer entered after the ping" rule, and lives on `PanelState`. `AppDelegate` turns the URL into `ping()`. `NotchPanelController.step` feeds it the hover state each frame, and `GamePanelView` draws the pulse.

**Tech Stack:** Swift 6, SwiftUI + AppKit, Swift Testing, Xcode JSON project (`NotchGames.xcodeproj/project.xcproj`).

**Spec:** `docs/superpowers/specs/2026-11-21-agent-attention-pulse-design.md`

## Global Constraints

- URL: scheme `notchgames`, host `attention`. Every other URL is ignored.
- The app never takes focus or the keyboard because of a ping.
- No game-code changes. The pulse never pauses play.
- The idle display link stays at 10 Hz. The pulse is a SwiftUI animation, not a controller-driven redraw.
- Write to `PanelState` only when the value changed (see the comment in `step`). Observation redraws on every write.
- With Reduce Motion on, show a steady glow instead of a pulse.

## Review Focus

1. **Pointer already on the panel at ping time (mid-game Pong/Air Hockey):** it stays on until the pointer leaves and comes back. Covered by `AttentionSignalTests.pointerAlreadyInsideKeepsItOn`.
2. **App not running when the hook fires:** `open -g` launches it and the ping still shows. `AppDelegate.panelState` exists before any URL arrives. Manual check in Task 2.
3. **A URL opens a stray window:** SwiftUI's lifecycle may try to route the URL to a scene. A ping must not open the Settings window. Manual check in Task 2.
4. **Repeated pings (`Notification` + `Stop` both fire):** a second ping while on stays on and doesn't flicker. Covered by `AttentionSignalTests.secondPingWhileOnStaysOn`.
5. **Mac without a notch, panel closed:** the overlay is hidden, so nothing shows. Opening the panel shows the pulse. Manual check in Task 3 if hardware is available, otherwise skipped and reported.

---

### Task 1: AttentionSignal

**Files:**
- Create: `NotchGames/NotchPanel/AttentionSignal.swift`
- Modify: `NotchGames/NotchPanel/PanelState.swift` (add property)
- Test: `NotchGamesTests/AttentionSignalTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated struct AttentionSignal: Equatable` with `private(set) var isOn: Bool` (default `false`)
  - `mutating func ping()`: turns it on and treats the pointer as already inside, so only a fresh entry clears it
  - `mutating func pointer(isInside: Bool)`: clears when `isInside` and the previous call was outside, then remembers `isInside`
  - `static func isRequest(_ url: URL) -> Bool`: true for scheme `notchgames` (case-insensitive) and host `attention`
  - `PanelState.attention = AttentionSignal()`

- [ ] **Step 1: Write the failing tests** in `NotchGamesTests/AttentionSignalTests.swift` (Swift Testing, same style as `OverlayHitTestTests`):
  - `startsOff`: `!AttentionSignal().isOn`
  - `pingTurnsItOn`: after `ping()`, `isOn`
  - `pointerAlreadyInsideKeepsItOn`: `ping()`, `pointer(isInside: true)` twice → `isOn`
  - `enteringAfterThePingClearsIt`: `ping()`, `pointer(isInside: false)`, `pointer(isInside: true)` → `!isOn`
  - `leavingAndComingBackClearsIt`: `ping()`, inside `true`, `false`, `true` → `!isOn`
  - `stayingOutsideKeepsItOn`: `ping()`, `pointer(isInside: false)` twice → `isOn`
  - `secondPingWhileOnStaysOn`: `ping()`, `pointer(isInside: false)`, `ping()` → `isOn`
  - `recognisesTheAttentionURL`: `isRequest` is true for `notchgames://attention` and `NotchGames://attention`, and false for `notchgames://other`, `https://attention` and `notchgames:attention`

- [ ] **Step 2: Run them and confirm they fail**
  Run: `xcodebuild test -scheme NotchGames -destination 'platform=macOS' -only-testing:NotchGamesTests/AttentionSignalTests`
  Expected: build failure, `cannot find 'AttentionSignal' in scope`.

- [ ] **Step 3: Implement `AttentionSignal`** to the interface above, using a private `pointerWasInside: Bool`. Add `var attention = AttentionSignal()` to `PanelState` with a one-line doc comment.

- [ ] **Step 4: Run the tests and confirm they pass.** Same command, expect `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit** `feat: add attention signal state`

### Task 2: notchgames:// URL scheme

**Files:**
- Create: `Config/NotchGames-Info.plist`. It has to sit outside `NotchGames/`: that folder is a synchronized group, and a plist inside it would be copied as a resource and clash with the generated Info.plist.
- Modify: `NotchGames.xcodeproj/project.xcproj` (NotchGames target build settings)
- Modify: `NotchGames/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `AttentionSignal.isRequest(_:)`, `PanelState.attention.ping()`

- [ ] **Step 1: Add the partial plist** with only `CFBundleURLTypes`: one entry, `CFBundleURLName` = `com.filippocilia.NotchGames`, `CFBundleURLSchemes` = `[notchgames]`. Set `"INFOPLIST_FILE": "Config/NotchGames-Info.plist"` in the NotchGames target and keep `GENERATE_INFOPLIST_FILE` = `YES`, so the two merge.

- [ ] **Step 2: Handle the URL.** Add `func application(_ application: NSApplication, open urls: [URL])` to `AppDelegate`. If any URL passes `AttentionSignal.isRequest`, call `panelState.attention.ping()`. Do nothing else: no activation, no `makeKey`.

- [ ] **Step 3: Build and check the plist**
  Run: `xcodebuild build -scheme NotchGames -destination 'platform=macOS' -derivedDataPath build/dd && plutil -p build/dd/Build/Products/Debug/NotchGames.app/Contents/Info.plist | grep -A4 CFBundleURLTypes`
  Expected: `BUILD SUCCEEDED`, and the output contains `notchgames`.

- [ ] **Step 4: Manual check (Review Focus 2, 3).** Quit the app, then run `open -g notchgames://attention`. It should launch with no window, and the terminal should keep focus. Run the same command again while it's running: still no window and no focus change. Until Task 3 lands nothing is visible, so check by adding a temporary breakpoint or `print`, then remove it. If SwiftUI swallows the URL so the delegate never gets it, stop and report back instead of working around it. `.onOpenURL` isn't a fallback here because there's no WindowGroup.

- [ ] **Step 5: Commit** `feat: register notchgames:// attention URL`

### Task 3: Hover clearing, the pulse, and the README

**Files:**
- Modify: `NotchGames/NotchPanel/NotchPanelController.swift` (`step`)
- Modify: `NotchGames/NotchPanel/GamePanelView.swift`
- Modify: `README.md`

**Interfaces:**
- Consumes: `PanelState.attention` (`isOn`, `pointer(isInside:)`)

- [ ] **Step 1: Feed hover in `step`.** After `updatePanelPointer`, compute `inside = anchor.notchRect.contains(location) || dropRect(in: anchor).contains(location)`. Call `pointer(isInside:)` on a copy of `state.attention`, and write it back only if it changed.

- [ ] **Step 2: Draw the pulse in `GamePanelView`** while `state.attention.isOn`:
  - Open: the existing neon outline gets an extra `Palette.paddle` stroke whose opacity pulses (about 0.9s ease-in-out, repeating, autoreversing).
  - Closed, with `state.hasNotch`: a blurred `Palette.paddle` glow `state.notchWidth` wide, hugging the notch's bottom edge just below `DropGeometry.notchCapHeight`, pulsing the same way.
  - Read `@Environment(\.accessibilityReduceMotion)`. When it's true, the glow holds steady at full opacity.
  - Exact sizes and opacities are the builder's call. The glow must not intercept clicks (`allowsHitTesting(false)`), and it must not change `dropRect`.

- [ ] **Step 3: Run the full test suite**
  Run: `xcodebuild test -scheme NotchGames -destination 'platform=macOS'`
  Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 4: Manual check.** Build and run, keep the pointer away from the notch, and run `open -g notchgames://attention`:
  - Closed: the notch glows and pulses, and moving the pointer onto the notch stops it.
  - Open in Pong with the pointer on the panel: it keeps pulsing. Moving off and back on stops it.
  - Reduce Motion on: the glow is steady.
  - No notch (Review Focus 5): test only if a non-notch display is available. Otherwise say it was skipped.

- [ ] **Step 5: README.** Add a short "Agent pings" section: what it does, `open -g notchgames://attention`, and this Claude Code hook snippet for `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [{ "hooks": [{ "type": "command", "command": "open -g notchgames://attention" }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "open -g notchgames://attention" }] }]
  }
}
```

- [ ] **Step 6: Commit** `feat: pulse the notch when an agent needs attention`

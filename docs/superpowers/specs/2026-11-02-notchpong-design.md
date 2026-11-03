# NotchPong — Design

> Renamed NotchGames on 2026-11-03 (project, targets, bundle ID `com.filippocilia.NotchGames`, folder `~/Developer/Projects/macOS/NotchGames`). It now has four games: Pong, air hockey, brick breaker and Snake. The GitHub repo was renamed to `cilippofilia/NotchGames` the same day.

Date: 2026-11-02
Status: Draft for approval

## Intent

A small macOS game you open by clicking the notch and dragging down. A game panel grows out of the notch as you pull, and you push it back up into the notch to close it. It's meant for a quick break from whatever you're doing, with no app to open and no window to switch to. The whole thing should feel instant and playful, as if the hardware is stretching. The first game is Pong against a computer opponent. The app ships on the Mac App Store.

## Goals (v1)

- Click the notch and drag down to pull out a Pong panel. The panel follows the pointer while you drag.
- The pull distance sets the panel size, between a **minimum (small)** and a **maximum (medium)**. Width and height scale together, so the court keeps its shape.
- Releasing leaves the panel open at that size.
- Dragging the panel's bottom handle back up into the notch closes it.
- Single-player Pong against a computer opponent, played with the mouse or trackpad.
- Mac App Store ready: sandboxed, no special permissions.

## Non-goals (v1) → planned for v1.1

User decision: these are out of v1 and go in the build plan as a v1.1 section.

- Air hockey as a second game. It should reuse the Pong paddle, ball, walls and scoring code.
- Two-player mode. Built locally on one keyboard, then dropped in favour of multiplayer between two Macs over the network, still to be planned.
- Scores saved between sessions.
- A settings window beyond Quit.

## Anti-goals

- The panel must never cover menu bar items. Within the menu bar it is exactly as wide as the notch.
- No Accessibility, Input Monitoring or Screen Recording permissions. (Changed 2026-11-02, user decision: the app polls the pointer position with `NSEvent.mouseLocation`/`pressedMouseButtons` to drive the magnet drop. That needs no permission and works in the sandbox.)
- No Dock icon or main window that gets in the way.

## Decided by the user

- **Magnet drop (2026-11-02, replaces the plain drag on the notch, which didn't work):** as the pointer nears the notch, a black tear-shaped drop stretches down from it and leans toward the pointer. Grabbing the drop (or the notch) and pulling down opens the game panel. The panel's neon outline starts on the flat top edge, the neck runs a little below the notch, and every corner uses the same radius.

- **Trigger:** click the notch and drag down. Pulling further makes the panel bigger.
- **Close:** drag the panel back up into the notch.
- **First game:** Pong against a computer opponent.
- **Distribution:** Mac App Store eventually.
- **Look: "Black + neon".** The panel is pure black (`#000000`, user decision 2026-11-02), so it blends into the notch. The paddles are teal (`#4dfcc4`) and glow, the ball is pink (`#ff4fa3`) and glows, and the center line is dashed. The panel has a faint teal outline glow and all four corners rounded (continuous, 28 pt). A small handle bar sits at the bottom center.
- **Shape:** a notch-width "neck" fills the menu bar height. Below the menu bar the panel widens into the court. The menu bar items on both sides stay visible.
- **Size range:** the "short pull" size is the minimum and the "medium pull" size is the maximum. In the mockups, at roughly 300 pt of screen height, those were about 170×100 and 240×160. The builder should turn them into real point sizes that look right on a 14" MacBook Pro and keep the ~3:2 to 1.6:1 court ratio.

## Decided by Claude (user can override)

- **Stack:** Swift 6, SwiftUI, macOS 26 or later, `@Observable` + `@MainActor` game state. AppKit is used only where SwiftUI can't do the job: a borderless, non-activating `NSPanel` at a level above the menu bar, positioned using `NSScreen.safeAreaInsets` / `auxiliaryTopLeftArea` / `auxiliaryTopRightArea` to find the notch.
- **App presence:** `LSUIElement` (no Dock icon) plus a `MenuBarExtra` with Quit, so App Review doesn't see a hidden app.
- **Idle trigger:** a small transparent panel always sits over the notch area to catch the mouse-down and drag. Clicks pass to it only inside the notch rectangle.
- **No-notch Macs and external displays (user decision):** no drag trigger strip, so it never sits over real menu items. Instead the `MenuBarExtra` gets a "Play Pong" item that drops the panel down from the top center at the medium (max) size. Closing still works by dragging the handle up or flicking it. On Macs with a notch, the menu item is there too.
- **Release behavior:** if the pull is released before reaching the minimum size, the panel snaps closed. Otherwise it stays at the size reached, clamped between min and max. Dragging the handle back up past the minimum, or a quick upward flick, also closes it.
- **Pausing:** the panel doesn't take focus from your app, so you can keep working with it open. The game auto-pauses when the pointer leaves the court and resumes when it comes back.
  - *Update 2026-11-03:* every game dims its court while paused, counting down or over. Keyboard-only games (Snake) pause on panel close, Settings or lost focus instead of pointer position, and the open panel takes the keyboard back when Settings closes.
- **Controls:** the player's paddle is on the right and follows the pointer's vertical position while the pointer is over the court. The arrow keys/W-S work too, for accessibility, while the panel is key.
  - *Update 2026-11-03:* held keys move at a steady speed every frame rather than relying on key repeat.
- **Match:** first to 5 points. Show the winner briefly, then offer to play again with a click. Closing the panel ends the match, and opening it starts a fresh one.
- **Computer opponent:** a paddle that tracks the ball with a max speed and a small reaction delay, so it's beatable. One difficulty level in v1.
- **Rendering:** SwiftUI `Canvas` driven by `TimelineView(.animation)`. Physics is a pure Swift model, unit-testable without UI.
- **Sound:** none in v1.
- **Project:** an Xcode project at `~/Developer/Projects/macOS/NotchPong`. Folders are organized by feature (`NotchPanel/`, `Pong/`, `App/`), and the game logic has unit tests (Swift Testing).

## Left to the builder

- Exact panel point sizes within the min/max described above, the animation curves, and the flick-velocity threshold.
- The ball speed curve, paddle sizes and computer reaction tuning.
- How the neck-to-court shape is drawn: one shape, or the neck and the body as separate shapes.
- How to handle multiple displays beyond "use the screen with the notch, otherwise the main screen".

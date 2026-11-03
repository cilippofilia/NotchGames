# Snake design

Date: 2026-11-03
Part of: v1.2 games (see `docs/superpowers/plans/2026-11-02-notchpong-v1.md`, "v1.2: more games")

## Intent

Classic phone-style Snake for a dead moment: steer a growing snake around a grid, eat food, don't crash, beat your best. It plays like the classic but looks like the rest of NotchGames (neon on black), not a copy of an old phone screen.

## Rules

- **Grid:** 32 × 20 square cells in a wide (1.6 : 1) panel, like Pong's.
- **Start:** a 3-cell snake in the middle, facing right. Food appears on a random free cell.
- **Movement:** one cell per step. A step takes 0.14 s, 3 ms less per food eaten, down to 0.06 s.
- **Eating:** +10 points and the snake grows by one cell.
- **Crashing:** running into its own body ends the run. Moving into the cell the tail is leaving is safe.
- **Walls (Settings › "snake walls", on by default):** on, hitting the edge ends the run. Off, the snake comes out of the opposite side. Toggling mid-run applies straight away. On draws a solid glowing border; off draws a faint dashed one. The border is inset 6 pt from the panel on every side with a 22 pt corner radius (the panel's 28 minus the inset), so it's concentric with the panel.
- **Full grid:** if there's no free cell for food, the run ends.

## Input: keys only

- Arrows or W/A/S/D steer. The pointer does nothing in Snake.
- Up to two quick turns are queued, each checked against the last queued direction, so up-then-left can't fold the snake into itself. Reversing is ignored.
- The first press of a fresh run may point backwards: the snake turns around rather than dying.
- An arrow press starts or resumes a waiting run through the 3-2-1 countdown. Space pauses and resumes. Return plays again after game over.

## Pausing

The game pauses when the panel closes, Settings opens or the view loses keyboard focus. The paused message reads "press an arrow to play". When Settings closes, the panel controller makes the open panel key again, so keyboard-only games keep working.

Known gap: clicking into another app while the panel stays open doesn't pause the game.

## Shared pieces

Reuses `MatchClock` (countdown, pause, 1/30 s frame cap; steps run off an accumulator), `MatchCountdownView`, `MatchMessageView` (with a `resumeHint`), `CourtDimView`, `ScoreNumber`/`ScoreLabel`, and `StatsStore.recordScore(_:for: .snake)`. Settings' record section shows "snake best". One best score covers both wall modes.

## Files

`NotchGames/Snake/`: `GridCell`, `SnakeModel` (rules, injectable random generator), `RunDisplay` (shared, in `Match/`), `SnakeGame` (loop, input, best score), `SnakeView`. Tests: `NotchGamesTests/SnakeModelTests.swift`.

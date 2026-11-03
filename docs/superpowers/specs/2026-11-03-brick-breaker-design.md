# Brick Breaker — Design

Date: 2026-11-03
Status: Built
Part of: v1.2 games (see `docs/superpowers/plans/2026-11-02-notchpong-v1.md`, "v1.2: more games")

## Intent

The first of the v1.2 games, and the one that sets up the shared pieces the other score-based games (Snake, runner, target tap) will reuse. It's a quick, endless game for a dead moment: pull the panel down, keep the ball alive as the wall creeps toward you, and try to beat your best score. It should feel like Pong's sibling: same neon look, same pointer steering, same pause and countdown behaviour.

## Rules (decided by the user)

- **Endless.** There's no wall to clear and no win. A run lasts as long as the player survives.
- **The wall comes down.** Bricks arrive from the top one row at a time. Each new row pushes the whole wall down by one row.
- **It speeds up.** The more time passes and the more rows the player gets through, the faster new rows arrive and the faster the ball moves.
- **3 lives.** Each ball that gets past the paddle costs one life. There are at most 3.
- **Game over** happens when the last life is lost, or when the wall reaches the paddle.
- **Score** combines bricks broken, rows survived and time (formula below; proposed by Claude, accepted by the user with "go ahead").
- **A taller panel is allowed.** This game may use a more vertical panel than Pong's 1.6 : 1 if it needs one (user, 2026-11-03).

## Score (proposed by Claude, accepted)

- **Bricks:** 10 points × the current speed level for each brick broken. The level starts at 1 and goes up each time the game speeds up.
- **Rows:** 25 points for each new row that drops in while the player is still alive.
- **Time:** 1 point per second survived, counting only while the ball is in play. Paused and countdown time don't count.

## Goals

- A new `GameKind.brickBreaker` (title "brick breaker", lowercase like the others), picked in Settings and shown by `GameView`.
- Its own `BrickBreakerGame` (`@MainActor @Observable`), `BrickBreakerModel` (plain struct, the physics) and `BrickBreakerView`, in a new `NotchPong/BrickBreaker/` folder, the same shape as Pong and Air Hockey.
- A best score per score-based game, kept between launches and shown on the game-over screen and in Settings' record section.
- Unit tests for the model and game logic, like `PongModelTests` / `PongGameTests`: bouncing, brick hits, row drops, speed-ups, lives, both game-over paths, scoring and the best score.

## Non-goals (this version)

- Power-ups, multi-hit or special bricks, more than one ball, hand-designed levels.
- Sound.
- Any change to how Pong and Air Hockey play or score.
- The paid unlock. That's deferred until all games are built (user decision, 2026-11-03).

## Anti-goals

- **Losing the player's existing record.** Adding the best score to the saved stats must not reset the wins, losses and streaks already saved. Saved data without the new field must still load. Today `PlayerStats` uses synthesized `Codable`, which fails on a missing key, so this needs explicit handling and a test that old saved data still decodes.
- **Per-frame view rebuilds.** Follow the `MatchDisplay` pattern from Pong: per-frame state stays `@ObservationIgnored`, and the court redraws from its `TimelineView`. Views around the court read a small display value that changes only on events.
- **Unfair starts.** Even with the taller panel, the opening drop rate must be gentle enough that a new player isn't buried in the first minute.
- **Covering menu bar items.** A different panel shape must still keep the existing rule: inside the menu bar the drop is never wider than the notch.

## Constraints

- Swift 6, SwiftUI, macOS 26, strict concurrency, the conventions in the user's CLAUDE.md (one type per file, no third-party code, tests for core logic).
- Court coordinates follow Pong's convention: y from 0 (top) to 1 (bottom), x from 0 to the court's aspect ratio, drawn into `CourtLayout.rect(in:)`. Brick breaker's x range matches its own panel shape.
- Reuse what exists: `Ball`, the swept-collision approach from `PongModel`, `MatchClock` (pause, countdown, capped frame steps), `CourtEffects` (glow, wall sparks, trail), `MatchCountdownView`, `MatchControlsView`, `ScoreNumber` / `ScoreLabel`, `Palette`.

## Claude's calls (for the user to check)

- **Panel shape.** Brick breaker gets a portrait panel, about 0.8 : 1 (width : height), so at the large size it's roughly 370 × 460pt instead of 736 × 460pt. That gives the wall about 1.6× more room to fall than a Pong-shaped panel would. Today the shape is one constant, `PullSizing.aspect = 1.6`, used by `PullSizing.bodySize` and `DropGeometry.width`. It becomes a per-game value read from the selected `GameKind`, with Pong and Air Hockey staying at 1.6. Switching games in Settings while the panel is open resizes the panel to the new shape. Panel size (small / medium / large) still sets the height.
  - *Update 2026-11-03:* it always opens at full size, 480 × 600pt (0.8 : 1), whatever the panel size setting, with the walls at the panel's edges.
- **Controls.** The pointer's left–right position steers the paddle, the way its height steers Pong's. Left/right arrows and A/D nudge it, as extras. This follows the v1.2 plan ("pointer main input, arrows as extras").
  - *Update 2026-11-03:* held keys glide the paddle every frame at a steady speed (`HeldKeys.speed`, 1.8 court units/s) instead of stepping on key repeat. Shared with Pong and Air Hockey.
- **Pausing.** Same as Pong: the game pauses when the pointer leaves the panel or Settings opens, resumes with a countdown when the pointer comes back, and keeps its state while the panel is closed.
  - *Update 2026-11-03:* the court dims (`CourtDimView`) while paused, counting down or over, so the countdown and messages read clearly over a full wall. Score, lives and best stay bright.
- **Speed level.** The level goes up every 5 rows dropped. Rows arrive on a timer, so both time and rows push it up. Each level shortens the row interval and raises the ball speed by fixed steps, each with a cap so the game stays playable.
- **Opening state.** 3 rows on screen at the start, then a new row every ~10 seconds at level 1. Final numbers are tuned by playing.
- **Wall layout.** A fixed number of columns across the court (about 10), each brick one hit. New rows are full rows. Each row slides down smoothly over a fraction of a second rather than jumping.
- **Wall reaching the paddle.** Game over when the bottom of the lowest row that still has bricks reaches the paddle's top edge.
- **Losing a life.** The ball resets above the paddle and a countdown runs (`MatchClock.startCountdown()`), the same as after a point in Pong. Rows don't drop during the countdown.
- **Paddle bounce.** Same as Pong: the bounce angle depends on where the ball hits the paddle, so the player can aim.
- **On screen.** The score sits at the top centre using `ScoreNumber`, the lives as 3 small teal dots beside it, and the best score as a smaller `ScoreLabel` ("best 1240").
- **Game over screen.** A `MatchMessageView`-style message: "game over", the score, "new best" or "best N", and "play again". `MatchMessageView` is built around a winner today, so it either gets a score-based case or brick breaker gets its own message view. The builder decides.
- **Best scores.** Stored next to `PlayerStats` in `StatsStore`, keyed by `GameKind` raw value, so Snake and the others can reuse it. Settings' record section shows the brick breaker best score, and "reset record" clears it too. *Update 2026-11-03:* Settings now has a tab per game; the brick breaker tab shows the best score and resets only it. Win/loss stats aren't affected by brick breaker runs.
- **A row dropping onto the ball.** If a new row would overlap the ball, the ball is pushed down below the row and keeps its velocity. A row drop never destroys bricks or costs a life by itself.
- **New best.** Only a score strictly higher than the saved best counts as "new best"; it's saved the moment the run ends.
- **Narrow panels.** At the small size a 0.8 : 1 panel can be narrower than the notch. `DropShape` already handles a body tucked under the notch, so this needs checking by eye, not new geometry.
- **Effects.** Wall sparks on wall bounces, a small explosion when a brick breaks, and the ball trail, all from `CourtEffects`.

## Left to the builder

- Exact sizes (brick size, gaps, paddle width, ball radius), speeds and caps, found by playing at every panel size.
- Whether `MatchDisplay` grows the fields brick breaker needs (score, lives, game over) or the game gets its own display value.
- How the swept collision against a grid of bricks is structured, as long as a fast ball can't pass through a brick in one step (the same guarantee `PongModel` gives for paddles).

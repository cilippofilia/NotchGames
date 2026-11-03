# Runner design

Date: 2026-11-03
Part of: v1.2 games (see `docs/superpowers/plans/2026-11-02-notchpong-v1.md`, "v1.2: more games")

## Intent

A notch version of Skate Run from cilippofilia.dev/games (the user's own game): a skater rolls along a street, jumps and ducks obstacles, and one hit ends the run. It keeps Skate Run's mechanics but is drawn to match the other NotchGames games, in neon on black (user, 2026-11-03).

## Rules (court units: 1.6 wide, heights up from the ground)

- **Speed:** the street scrolls at 0.6 units/s, gaining 0.012 units/s every second, up to 1.4.
- **Score:** 10 points per unit travelled. The best is kept per game ("runner best" in Settings' record).
- **Jump:** space, ↑ or W. A tap gives a short hop. Holding it lightens gravity for up to 0.18 s for a higher, longer jump. Holding it through a landing hops again.
- **Duck:** ↓ or S. On the ground the skater crouches (11 → 6 pixels tall). In the air it dives (heavier gravity).
- **Hit boxes:** shrunk 0.012 units on each side, so near misses feel fair. Any overlap ends the run.

## Obstacles

Four of Skate Run's ways to clear something, as pink pixel sprites:

| Kind | Clear by | From score | Notes |
| --- | --- | --- | --- |
| cone | tap jump | 0 | rows of 1–2, up to 3 once speed ≥ 1.0 |
| pigeon | duck | 60 | flies between a ducking and a standing head, wings flap |
| bench | held jump | 120 | a tap can't clear it at the start speed (tested) |
| cart | tap jump | 250 | rolls toward the skater 0.3 units/s faster than the street |

Cones are three times as likely as the others. The next obstacle comes 0.9–1.5 s of travel later (×1.3 after a bench, plus room for a cart's own speed).

## Look

A teal pixel skater on a glowing ground line, with dashes below that scroll with the street. On a crash the skater tips over. One skater only, no character picker. The court dims while waiting (`CourtDimView`).

## Input and pausing: keys only

- A jump press starts or resumes a waiting run through the 3-2-1 countdown. Escape pauses or resumes. Return plays again after game over. The pause hint reads "press space to play".
- It pauses when the panel closes, Settings opens or keyboard focus goes elsewhere, and takes focus back when the panel opens or Settings closes (same as Snake). Held keys are forgotten on focus changes.
- No online leaderboard (Skate Run posts scores; this doesn't).

## Files

`NotchGames/Runner/`: `RunnerObstacle` (kinds and boxes), `RunnerModel` (physics, spawning, injectable random generator), `RunnerSprites` (pixel rows), `RunnerGame` (loop, input, best score), `RunnerView`. Shares `RunDisplay` with Snake. Tests: `RunnerModelTests` (jump arc, held jump, dive, collisions, ducking, speed cap, spawn gating, clearability) and `RunnerGameTests`.

## Left to tune by playing

Speeds, gravity, gaps and score thresholds are first guesses, checked only by tests.

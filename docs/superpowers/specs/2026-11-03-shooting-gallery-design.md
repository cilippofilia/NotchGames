# Shooting gallery design

Date: 2026-11-03
Status: Built 2026-11-03
Part of: v1.2 games (see `docs/superpowers/plans/2026-11-02-notchpong-v1.md`, "v1.2: more games"). Replaces the planned "target tap".

## Intent

A pointer-and-shoot game in the style of the classic light-gun bird shooters, asked for by the user. It's original: neon pixel birds on black, matching the other NotchGames games, with no characters, art or names taken from any existing game.

## Rules (court units: 1.6 × 1, y down)

- **Rounds:** 10 birds per round, released in pairs from the ground line (y 0.9).
- **Shots:** 3 per pair. A click while a pair is flying uses a shot; clicks between pairs don't. A shot within 0.065 units of a flying bird's center hits the nearest one.
- **Flight:** birds zigzag, changing direction every 0.5–1.2 s, and bounce off the sides, the top and just above the ground. Speed is 0.45 units/s in round 1, +0.08 per round, up to 1.2.
- **Escape:** a pair escapes straight up off the top after 5 s (−0.3 s per round, down to 3 s), or as soon as its shots run out. Escaped birds count as misses. Shot birds tumble to the ground and count as hits.
- **Quota:** hit 6 of 10 to pass round 1, one more every two rounds, up to 9. Passing shows a "round N clear" screen (hits, perfect bonus, next quota) that waits for "next round" or a click on the court, then counts the next round in. Falling short ends the run.
- **Score:** 100 × round per bird, plus 1000 × round for a perfect 10/10. The best score is kept in the shooting gallery's Settings tab.

## Look

- Pink pixel birds with flapping wings that face the way they fly. A shot bird flips upside down, dims and falls.
- A teal crosshair follows the pointer. Each shot flashes the court briefly. A hit throws a spark, and a miss leaves a fading teal ring.
- A glowing ground line, and the dimmed court while waiting.
- The strip along the top shows "round N" with a dot per bird (lit when hit, dim when missed, outlined while still to come), "hit Q to pass", the score and best, and the shots left as three bars.

## Input and pausing: pointer only

The pointer aims and a press shoots, once per press. Like Pong, the game pauses when the pointer leaves the panel (past the gutter) and resumes through the countdown when it comes back. Restart, Settings and play again use the shared match screens.

## Files

`NotchGames/ShootingGallery/`: `GalleryBird`, `GalleryModel` (rules, injectable random generator), `GalleryDisplay`, `GalleryGame` (loop, input, best score), `GalleryView`, `GalleryHUDView`, `GallerySprites`, `RoundSummary`, `RoundSummaryView`. Tests: `GalleryModelTests`, `GalleryGameTests`.

## Left to tune by playing

Speeds, escape times, hit radius and the quota curve are first guesses, checked only by tests. The system pointer still shows under the crosshair.

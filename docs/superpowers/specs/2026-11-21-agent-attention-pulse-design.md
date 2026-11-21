# Agent attention pulse — design

## Why
While playing in the notch you lose track of agents (Claude Code and others) running in a terminal. When one finishes or is
waiting on you, the notch should catch your eye so you go back to it.

## Goals
- Any agent or script can ask for attention with `open -g notchgames://attention`.
- Panel open: the panel's neon outline pulses.
- Panel closed: the notch glows, pulsing along its bottom edge.
- The pulse stops when the pointer moves onto the notch or the panel after the ping.

## Non-goals
- No message, agent name, count or sound: it's a single on/off signal.
- No "clear" URL. Hovering is the only way to dismiss it.
- No menu-bar indicator on Macs without a notch. There, the overlay is hidden while closed, so the pulse only shows
  while the panel is open.
- No game-code changes, and the pulse never pauses or affects play.

## Anti-goals
- Stealing focus or keyboard from the terminal (that's why `open -g`).
- A full-rate redraw loop while idle: the pulse must not keep the display link at 120 Hz all the time.

## Approaches
- **URL scheme `notchgames://attention` (picked).** The OS delivers it, it works from any shell hook, and it adds no
  server or helper binary.
- System-wide notification (`DistributedNotificationCenter`): nothing on the command line can post one, so it would
  need a helper binary.
- Local HTTP server: adds a listener, a possible port clash and a network entitlement for a one-bit signal.

## Design
- Register the `notchgames` URL scheme. The project generates its Info.plist, and `CFBundleURLTypes` has no
  `INFOPLIST_KEY_` setting, so it goes in a small partial Info.plist that the build merges in. The app sandbox doesn't
  block receiving URLs.
- `AppDelegate.application(_:open:)` sets `PanelState.needsAttention = true` for the `attention` host and ignores every
  other URL.
- `GamePanelView` animates a pulsing glow while `needsAttention` is set: on the panel outline when open, and as a glow
  under the notch's bottom edge when closed, inside the existing overlay window's notch cap.
- `NotchPanelController.step` clears `needsAttention` when the pointer *enters* the notch rect or the drop/panel rect
  after the ping arrived. A pointer that was already there (e.g. mid-game in Pong or Air Hockey) doesn't clear it:
  it has to leave and come back, or the panel has to close and be hovered again. (Decided with the user: a plain
  "is hovering" check would clear the ping instantly while playing.)
- The pulse runs as a SwiftUI animation, so the controller's 10 Hz idle check is enough to spot the hover.

## Claude Code hook (documented in the README, not installed by the app)
`Notification` and `Stop` hooks in `~/.claude/settings.json` running `open -g notchgames://attention`.

## Left to the builder
The exact pulse look (color from `Palette`, timing, glow size), and whether the README shows the hook JSON in full.

## Revision (2026-11-21): auto-stop instead of hover dismissal
Trying it showed hover dismissal fails mid-game: the pointer is busy on the panel, and the `Stop` hook pings after
every agent reply, so the pulse rarely ended. The final review also found that gutter slips cleared it by accident,
that a no-notch Mac could clear it before anything was shown, and that the endless animation kept redrawing.
Decided with the user:
- Each ping plays once for **5 seconds**: the glow fades in, three short sideways buzzes (stronger than the old
  breathing pulse), then fades out. There is no dismissal and no hover tracking. A new ping restarts it.
- Built as a one-shot SwiftUI `keyframeAnimator` triggered by a ping counter on `PanelState`. One clock runs 0 to 5 s,
  and `AttentionSignal.glow(at:)` and `shake(at:)` turn it into glow and offset. Those are pure functions, unit-tested.
- Rejected: an on/off flag cleared by a controller timer. It has more moving parts and nothing else needs the flag.
- Reduce Motion: glow only, no shake.

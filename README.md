# NotchGames

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-black?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

A small macOS menu bar app with six neon arcade games that you pull out of the notch. Move the pointer toward the notch and a black drop stretches down to meet it. Pull the drop down and a game panel opens. Push it back up when you're done. You don't have to open a window or switch apps.

**[Download NotchGames](https://cilippofilia.dev/notchgames)**

[//]: # (Add a screenshot or short GIF of the drop opening into a game here; it's the fastest way to show what the app does.)

## Games

| Game | Mode | Controls |
| --- | --- | --- |
| **pong** | vs. computer, first to 5 | pointer height, or ↑/↓ and W/S |
| **air hockey** | vs. computer | pointer, or arrows and W/A/S/D |
| **brick breaker** | endless, best score, power-ups | pointer left/right, or ←/→ and A/D |
| **snake** | endless, best score | arrows or W/A/S/D, space to pause |
| **runner** | endless skater, best score | space/↑/W to jump (hold to jump higher), ↓/S to duck |
| **shooting gallery** | rounds with a hit quota | click to shoot, 3 shots per pair of birds |

Pick a game with the arrows on the title screen or in Settings.

## How it works

- **Open:** move toward the notch, grab the drop and pull down. How far you pull sets the panel size.
- **Close:** drag the panel back up into the notch, or flick it upward.
- **No notch or an external display:** choose **play** from the menu bar icon and the panel drops from the top center of the screen.
- **Pausing:** the panel never takes focus from the app you're working in. Pointer games pause when the pointer leaves the court and count back in when it returns. Keyboard games pause when the panel closes or loses focus.

The app has no Dock icon and needs no Accessibility, Input Monitoring or Screen Recording permission.

## Settings

Open Settings from the menu bar icon. The **General** tab picks the default game, the panel size, how far the pointer can stray before a game pauses (the gutter), and launch at login. Each game also has its own tab with its difficulty and your record or best score.

## Requirements

- macOS 26 or later
- A MacBook with a notch for the pull gesture. Other Macs use the menu bar **play** item.

## Building

Open `NotchGames.xcodeproj` in Xcode and run the `NotchGames` scheme. Tests live in `NotchGamesTests` (Swift Testing):

```sh
xcodebuild test -scheme NotchGames -destination 'platform=macOS'
```

### Release

`scripts/release.sh` archives a Developer ID signed build, packages it as a DMG, then notarizes and staples it. It needs a "Developer ID Application" certificate in the keychain and a logged-in [`asc`](https://github.com/rudrankriyam/App-Store-Connect-CLI) CLI.

```sh
scripts/release.sh   # writes build/release/NotchGames-<version>.dmg
```

## Project layout

```
NotchGames/
  App/          app entry, menu bar item, palette
  NotchPanel/   notch geometry, the magnet drop, pull and close gestures
  Games/        AirHockey, BrickBreaker, Pong, Runner, ShootingGallery, Snake
  Match/        shared court, countdown, score and pause views
  Title/        title screen and game picker
  Settings/     General and per-game tabs, login item
  Stats/        records and best scores
docs/superpowers/ design specs and build plans
```

## License

MIT. See [LICENSE](LICENSE).

# NotchPong: 🟡 Reshape (ship it soon, not later)

App idea check, 2026-11-02. Run on NotchPong as a Mac app (not the iOS default).

**Pitch:** You're waiting on a build or an AI reply. Pull the notch down for a 30-second neon game, then push it back up.
In "X for Y" form: a tiny arcade for Mac people who are stuck waiting.

**Big bet:** I believe Mac users with a notch want a quick, good-looking game one gesture away, because waiting on builds and AI replies is now a daily dead moment, and the notch feels like a toy waiting to be played with.

**Would disprove it:** the notch-game apps already on sale have no traction a few months after launch, and nobody on r/macapps or Product Hunt reacts to a demo clip.

## Kill switches

- ✅ **Payment:** a one-time purchase fits, and competitors already charge $1.99–$4.99.
- ✅ **Compliance:** none. It's a sandboxed game with no data collection.
- ✅ **Infrastructure:** no server. Network multiplayer later would add a local network permission prompt, but still no backend.
- ⚠️ **Platform risk:** it only works on Macs with a notch, and a macOS change to how the menu bar or notch behaves could break the panel.
- ✅ **v1 size:** Pong, air hockey, settings and stats are already built.
- ⚠️ **Edge over rivals:** there is no app to switch away from, but small copies are piling up (see below). You win on feel and polish, not on being first.
- ✅ **Skill gap:** none. It's SwiftUI and Canvas, which are already shipping.

## Market evidence

- **Demand:** the notch is a proven Mac App Store category. Dozens of notch utilities were updated in the past few months. NotchNook reportedly made about $100k in its first week at $25 lifetime or $3/month. That shows Mac users will pay for clever notch software, though NotchNook is a utility, not a game.
- **Direct competitors** (iTunes Search API, US, checked 2026-11-02):

| App | Price | Ratings | Last update | Weakness |
|---|---|---|---|---|
| BuenasNotches – Notch Games | $3.99 | 0 | Feb 2026 | Pitches the same "tiny arcade" idea and has no visible traction |
| Mini Pong – Menu Bar Game | $1.99 | 0 | Apr 2026 | Same pitch ("breaks during builds or AI responses"), menu bar only |
| Mini Break – Menu Bar Game | $1.99 | 0 | Apr 2026 | Same developer as Mini Pong; one game per paid app |
| Swish Notch | $4.99 | 0 | Oct 2026 | A gimmick: basketball as a way to send files |
| Hit The Notch | Free | 0 | Oct 2026 | Really a screensaver |

- **What users say:** reactions to notch apps are split. Playful ones like Notchmeister get called "silly but fun", which works for a $3 impulse buy. Expensive utilities got pushback on price.
- **Read:** this is a new, crowded niche of very small apps. Nobody has won it, and nobody has shown it pays much. The API reports 0 ratings for almost every Mac app, so rating counts tell us little here. Real download numbers would need Sensor Tower or Appfigures.

## Scores

- **Goldilocks (1–5):** desirability 3, feasibility 5, viability 2.
- **RICE** = reach 3 × impact 3 × confidence 4 ÷ effort 2 = **18**. Low reach, but very cheap to finish.
- **What sets it apart:** no single feature is dramatically better. The edge is a drop-down panel that feels physical, plus several polished games in one app at about the price of one competitor game.
- **Distribution: 3/5.** A short screen recording on r/macapps, Product Hunt, Show HN and developer social media is the whole launch. Searching the App Store for "notch game" is a thin channel.
- **How much you want to build it:** yes. You'd enjoy building and polishing these games for six months or more, even if the app only ever pays for the developer account. That's the strongest point in its favour: small earnings plus real enjoyment is a sound portfolio app.

## Money

**Model:** free download with Pong included, and a one-time **$3.99** unlock for air hockey and the v1.2 games. "Always charge something", and a one-time price matches the category. A subscription doesn't fit a game you play in bursts.

About $3.39 per sale after Apple's 15% cut.

| Goal | Sales needed | Plausible? |
|---|---|---|
| Pay for the developer account ($99/yr) | about 30 a year | Yes, from one decent launch post |
| Coffee money ($100/mo) | about 30 a month, roughly 350 a year | Possible if a clip goes viral once |
| Sustainable ($30k/yr) | about 8,850 a year | Not on current evidence |

**Realistic first year:** pays for the developer account, with a shot at coffee money.

## v1, and the reshape

**The reshape is about timing.** Ship Pong and air hockey now, and release Snake, the runner, brick breaker and target tap as free updates. Each update is another reason to post a new clip. Waiting until all six games exist delays the only test that matters, which is whether strangers buy it.

- **The one behaviour that proves the bet:** someone pulls the panel down during a wait, plays a game, and does it again the next day.
- **Go deep on:** the pull-down feel and the neon look. That's what people will share.
- **Cut for now:** network multiplayer. It's the most expensive item on the list and doesn't help prove the bet.

## Next cheapest tests

1. Record a 15-second clip of pulling the panel down and playing Pong, and post it on r/macapps or developer social media. Upvotes and "where can I get this?" replies are the demand signal.
2. Look up BuenasNotches and Mini Pong downloads in Sensor Tower or Appfigures. If they sell almost nothing, aim for the developer-account goal and treat this as a portfolio app.
3. Ship to TestFlight for a few developer friends, and ask them later: "When did you last open it, and what were you waiting for?"

## Sources

- [iTunes Search: "notch"](https://itunes.apple.com/search?term=notch&entity=macSoftware&country=us&limit=25)
- [iTunes Search: "notch game"](https://itunes.apple.com/search?term=notch%20game&entity=macSoftware&country=us&limit=15)
- [iTunes Search: "menu bar game"](https://itunes.apple.com/search?term=menu%20bar%20game&entity=macSoftware&country=us&limit=15)
- [iMore: NotchNook made $100k in seven days](https://imore.com/apps/mac-apps/this-macbook-app-generated-dollar100000-in-seven-days-now-stripe-wont-pay-up)
- [MacRumors: Notchmeister](https://www.macrumors.com/2021/12/17/notchmeister-decorate-macbook-pro-notch/)
- [MacRumors forum thread on Notchmeister](https://forums.macrumors.com/threads/notchmeister-lets-you-decorate-the-notch-on-your-macbook-pro.2328031)
- [MacSparky: Leaning Into the Notch](https://macsparky.com/?p=13855)
- [Daring Fireball on Notchmeister](https://daringfireball.net/linked/2021/12/20/notchmeister)
- [BGR: apps that make the notch useful](https://www.bgr.com/2177168/apps-that-make-macbook-notch-useful/)
- [Mezha: NotchNook launch](https://mezha.media/en/2024/07/22/the-notchnook-app-has-been-released-for-macbook-which-makes-the-camera-cutout-on-top-of-the-screen-functional)

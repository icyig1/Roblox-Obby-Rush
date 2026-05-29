# One-Minute Obby Rush - First Playable Plan

## Core promise

Fast randomized obby races that restart every minute. Players understand the game immediately: survive short rooms, reach checkpoints, finish before the timer, earn coins, and show off cosmetics.

## Why this is a good first Roblox game

- Small maps are faster to build than one giant world.
- Obby mechanics are familiar to Roblox players.
- Random room order makes the same content feel replayable.
- You can ship a playable version quickly, then add rooms weekly.
- Monetization can be cosmetic/convenience focused without ruining the game.

## MVP feature set

1. Script-generated lobby, waiting area, and obby course.
2. Queue pad with a 15-second countdown once at least 2 players enter.
3. Max 10-player race rounds with a 60-second timer.
4. Randomized room sequence each round.
5. Checkpoints after every room.
6. Coins, wins, best time, XP, and levels.
7. Persistent player data with DataStore fallback in Studio.
8. Simple HUD with timer, stats, status, and progress.
9. Shop panel with placeholders for gamepasses and developer products.
10. Finish rewards and completion messages.
11. Hazard floor respawn back to last checkpoint instead of full round failure.

## First update roadmap

### Version 0.1 - Playable

- Use the scripts in this repo.
- Test every room in Roblox Studio.
- Set the round to 6-8 rooms until the timing feels right.
- Publish privately and invite friends to test.

### Version 0.2 - Retention

- Add daily reward chest in the lobby.
- Add 5-10 more room templates.
- Add a daily leaderboard for fastest finish.
- Add streak rewards for finishing multiple rounds in a row.

### Version 0.3 - Monetization

- Create gamepasses:
  - 2x Coins
  - VIP Trail
  - Speed Coil or +2 WalkSpeed
- Create developer products:
  - Skip Room
  - Small Coin Pack
  - Revive/Return to Checkpoint
- Add 6-12 trail colors purchasable with earned coins.

## Visual design

The game should feel bright, readable, and fast:

- Lobby: clean white/green platform, large round timer sign, leaderboard wall.
- Courses: high-contrast room colors, obvious safe platforms, red/orange hazards.
- UI: timer at the top, stats along the top-left, shop button on the right.
- Cosmetic direction: neon trails, victory bursts, finish-line confetti.

## Monetization principles

- Do not make players pay to finish the obby.
- Sell speed, style, time-savers, and social status.
- Make earned coins useful so free players still feel progression.
- Keep paid advantages mild enough that leaderboards still feel fair.

## Studio setup

If using Rojo, sync `default.project.json`.

If using Roblox Studio manually:

1. Create a ModuleScript in `ReplicatedStorage` named `ObbyRushConfig`.
2. Paste in `src/ReplicatedStorage/ObbyRushConfig.lua`.
3. Create a Script in `ServerScriptService` named `OneMinuteObbyRushServer`.
4. Paste in `src/ServerScriptService/OneMinuteObbyRush.server.lua`.
5. Create a LocalScript in `StarterPlayer > StarterPlayerScripts` named `ObbyRushClient`.
6. Paste in `src/StarterPlayer/StarterPlayerScripts/ObbyRushClient.client.lua`.
7. Press Play.

## Important publishing steps

- Enable Studio API access before expecting DataStores to save in Studio.
- Replace all `0` gamepass/product IDs in `ObbyRushConfig` after creating them on Roblox.
- Test with at least two players using Studio's local server test.
- Keep round length at 60 seconds unless rooms become much harder.

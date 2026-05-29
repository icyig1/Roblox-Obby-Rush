# One-Minute Obby Rush

Starter Roblox game package for a fast, randomized obby race.

Open [DESIGN_PLAN.md](DESIGN_PLAN.md) first. The scripts are organized so you can either sync them with Rojo or paste them directly into Roblox Studio.

## Files

- `src/ReplicatedStorage/ObbyRushConfig.lua` - tuning, rewards, and monetization IDs.
- `src/ServerScriptService/OneMinuteObbyRush.server.lua` - lobby, rounds, rooms, coins, data, purchases.
- `src/StarterPlayer/StarterPlayerScripts/ObbyRushClient.client.lua` - HUD, status messages, shop prompts.

## Quick start in Roblox Studio

1. Add the three scripts to the matching Roblox services.
2. Press Play.
3. Tune room count, rewards, and product IDs in `ObbyRushConfig`.

The server script generates the lobby and course automatically, so you do not need to hand-build a map before testing.

## Queue and shop setup

- Players step on the green `ONE-MINUTE OBBY RUSH` pad to enter the waiting area.
- The round countdown starts when `Config.MinPlayersToStart` players are queued.
- `Config.MaxPlayersPerRound` controls the room cap. It is currently `10`.
- Players are sent to the yellow `RoundExitPad` when the round ends, so they do not instantly queue again.
- Touching the blue `SHOP` pad opens the same shop UI as the on-screen shop button.
- For solo Studio testing, `Config.MinPlayersToStart` is currently `1`. Change it back to `2` before public multiplayer testing.

To move lobby/waiting pads, edit `Config.PointPositions` in `ObbyRushConfig.lua`:

- `QueuePad` moves the green obby rush pad.
- `ShopPad` moves the blue shop pad.
- `RoundExitPad` moves the yellow post-round pad.
- `LeaveQueuePad` moves the red leave-queue pad.

To configure your own shop:

1. Create Game Passes or Developer Products on Roblox.
2. Copy their numeric IDs into `Config.GamePassIds` or `Config.ProductIds`.
3. Change the button names/colors in `shopButtons` inside `ObbyRushClient.client.lua`.
4. Add the server reward/effect in `handleProduct` or `PromptGamePassPurchaseFinished` inside `OneMinuteObbyRush.server.lua`.

## Troubleshooting

If Roblox Studio prints `Failed to parse secrets: Can't parse JSON` while you are opening Game Settings, Security, HTTP settings, or API Services, that warning is a Roblox Studio/Game Settings issue, not this server script. It can appear even in new places. You can usually keep testing the game unless the Output also shows a red stack trace that names `OneMinuteObbyRushServer`.

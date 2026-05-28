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

## Troubleshooting

If Roblox Studio prints `Failed to parse secrets: Can't parse JSON` while you are opening Game Settings, Security, HTTP settings, or API Services, that warning is a Roblox Studio/Game Settings issue, not this server script. It can appear even in new places. You can usually keep testing the game unless the Output also shows a red stack trace that names `OneMinuteObbyRushServer`.

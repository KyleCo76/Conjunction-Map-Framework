# Conjunction Map Framework 1.0.0

The Conjunction Map Framework (CMF) is one world map for The Witcher 3: Wild Hunt Remastered that other map mods and icon packs work through, so several of them can be installed at the same time.

This folder holds the release archives exactly as they were tested: they are the same bytes as release candidate `1.0.0-preview-5`, with only the file names changed.

## Contents

| Archive | What it is | Install |
| --- | --- | --- |
| `mod0000_ConjunctionMapFramework-1.0.0.zip` | CMF itself (script API 6) | Required |
| `modCMFMinimapPanel-1.0.0.zip` | Optional minimap add-on | Optional; never beside another minimap mod |
| `modCMFExampleIconPack-1.0.0.zip` | Sample icon pack, an example for pack authors | Optional |
| `modCMFAdapterAllQuestObjectives-1.0.0.zip` | All Quest Objectives adapter | With All Quest Objectives On Map - Remastered 1.2.1 |
| `modCMFAdapterBotanist-1.0.0.zip` | Botanist adapter | With Botanist - NG - Remastered 3.0.0.2 |
| `modCMFAdapterFogOfWar-1.0.0.zip` | Fog of War adapter | With Fog of War 1.2.1 |
| `modCMFAdapterGwentPlayersMap-1.0.0.zip` | Gwent Players Map adapter | With Gwent Players Map 1.0.9 |
| `modCMFAdapterInkAndIron-1.0.0.zip` | Ink and Iron adapter | With Ink and Iron AIO 0.8.8 (0.8.7 works too) |
| `modCMFAdapterMapPinTeleport-1.0.0.zip` | Map Pin Teleport adapter | With Map Pin Teleport 1.2.2 |
| `modCMFAdapterMapQuestInsight-1.0.0.zip` | Map Quest Insight adapter | With Map Quest Insight 1.6.1 |
| `modCMFAdapterTheStable-1.0.0.zip` | The Stable adapter | With The Stable 2.2.1 |
| `modCMFAdapterWitcherGearMap-1.0.0.zip` | Witcher Gear Map adapter | With Witcher Upgrade Gear Map 1.0.1 |
| `modCMFAdapterWitchersPath-1.0.0.zip` | Witcher's Path adapter | With Witcher's Path 1.0.3 |

Each archive mirrors the game folder and has a `README.txt` at its root with the full install, update and removal steps. Adapters contain none of the mods they adapt; install those from their authors. Nothing in these archives runs outside the game.

## Requirements

- The Witcher 3: Wild Hunt Remastered, Steam patch 5.01 (build 5.0.1048522), DirectX 12, on Windows.
- Each adapter needs the mod it adapts, at the version named in that adapter's `README.txt`.

## Install

1. Extract the CMF archive to a temporary folder.
2. Copy its `Mods` and `bin` folders into your game folder and let Windows merge them.
3. Install the mods you want to adapt as their authors describe, then the matching adapter archives (`Mods` only). Optionally add the minimap add-on.
4. Start the game. The first start recompiles scripts and takes a little longer.

## Check a download

In PowerShell, in the folder with the archive:

```
Get-FileHash .\mod0000_ConjunctionMapFramework-1.0.0.zip -Algorithm SHA256
```

The result must equal that file's line in `SHA256SUMS`.

## How this release was tested

See `test-notes.md`: where and how it was tested, and what was not tested.

## Removing or going back

See `rollback-notes.md`. In short: remove adapters and packs first, then the minimap add-on, then CMF.

## Known limits

- Not tested: controllers, Proton / Linux, installing through a mod manager.
- A map mod that still ships its own copy of the world map keeps its scripts and menus, but its own map-screen look does not show while CMF is installed, until that mod is ported to CMF or a CMF adapter for it is installed.
- Placeholder art in the All Quest Objectives, Botanist, Gwent Players Map, Map Quest Insight and Witcher Gear Map adapters until their authors supply theirs. Fog of War's clouds and Map Remastered's own region emblems do not draw on CMF's map.
- No adapter for Smooth Map or Community Patch - World Map: they change only their own map file, so an adapter could not tell whether they are installed.
- When two packs change the same thing, the pack whose folder name sorts first wins.
- The minimap add-on replaces the minimap and clashes with other minimap mods.

This is an unofficial fan work and is not approved/endorsed by CD PROJEKT RED.

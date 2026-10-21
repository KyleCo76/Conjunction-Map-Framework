# The Stable adapter

`modCMFAdapterTheStable` is a separate mod that sits between Conjunction Map Framework (CMF) and The Stable - Roach-Horse Customization Mod 2.2.1 (Nexus 6132). The Stable ships its own copy of the game's world map file, whose only change is one filter row: the game's `Stables` pins under NPCs. Under CMF that map file does not load, because `mod0000_ConjunctionMapFramework` sorts ahead of `modArdDhuStable`, so The Stable's horseshoe markers still draw but have no filter row. The adapter asks CMF for that row through CMF's general call, adds nothing of its own and ships no art. The author-facing version is [`docs/authors/the-stable-adapter.md`](../../../docs/authors/the-stable-adapter.md).

## Provenance

Read only on 2026-10-20, from Kyle's reference archive in `source/compatability-candidates/` on his PC (never copied into the repository):

| File | SHA-256 |
|---|---|
| `The Stable 6132 2.2.1 2026-10-14T09-59Z DzkABbDNl.zip` | `45901e0733e6de3c8a1fd0a5b79043ff4dc0912dd4aaf155cb2f75529ffc8f96` |
| `Mods/modArdDhuStable/content/blob0.bundle` | `b9797b87de13f904b9635cffac3715167699cf8c50050493761b8a0db949b7d7` |
| `Mods/modArdDhuStable/content/metadata.store` | `fa32b7cc3748425041049bfd3827accc4b4b4a62b48f330d7d2721f902eaac32` |
| `Mods/modArdDhuStable/content/precompiled.rsblob` | `6141a32ca8388960ce0fe6a6a8cac173ff7b9758679a3ac0ce20d84960b735c6` |
| `gameplay\gui_new\swf\worldmap\panel_worldmap.redswf` (inside the bundle) | `19cbc01f2538878d23c8d20f12fcbe4195ce232d9c68209eb2e6046eaba75725` |
| its movie | `86b91c1b49f9312c9ca7c4c24cfd9300b31b1ab8dcad855591a5a2535211d351` |
| `HubMapPinPanel.as` (FFDec 26.3.0 export) | `75b4abb0b72329cf9082927f23871bb9d6c2f316ed24a42ad94746b34226a9bc` |

The archive holds `Mods/modArdDhuStable` (the bundle above, its `metadata.store`, and the scripts as a precompiled `precompiled.rsblob`; no `.ws` files) and `dlc/dlcArdDhuStable` (the stable masters, horses, scenes and strings, 361 MB unpacked). It has no settings file. The bundle holds the map file and nine horse resources (`player_horse.w2ent`, the horse item definitions, the demonic saddle).

The map movie was exported with FFDec 26.3.0 (JAR `1587e60b…a841c`, the pinned one) and compared with two references:

- **The game's legend.** `HubMapPinPanel._pinTypeDefinitions` parses to 119 rows. Without `"Stables": new PinTypeDefinition("NPCs", 516)` the other 118 match the pinned 5.01 legend digest of `tools/cmf_pin_types.py` (`25d8e7c0…5ac005`). The seven `_categoryDefinitions` are the game's (no new tab). The pin sprite (DefineSprite 588) is byte for byte the game's (`d9b5f0da…81d4`, 144 frames), so the Stables marker is the game's own drawing. The movie runs at the game's 24 frames per second.
- **Community Patch - World Map 2.0.0.0 (Vanilla)**, whose map file is the game's plus Botanist, The Stable and Smooth GUI (its `HubMapPinPanel.as` exports to `ec2707ab…4566`, as the Community Patch adapter recorded). Every exported script is identical except `HubMapPinPanel.as` and `MapMenu.as`. The differences are exactly Community Patch's Botanist tab, rows and frames, its 60 frames per second, the Stables row's place in the table (Community Patch lists it after `Bookshelf`, The Stable after `Cammerlengo`; the key and value are the same), and two decompile-only spellings in `HubMapPinPanel` (`Boolean(x)` against `(Boolean(x))`, a local typed `*` against `Boolean`) with the same behaviour. The only other movie tags that differ are the exporter's build id in the image names and the sprite and code tags that hold Botanist's frames and rows.

So The Stable's map file is the game's 5.01 map with one row added. Nothing is copied: the adapter holds only the type name, the category and the priority, which are facts about the interface.

### The Stable's scripts

The Stable 2.2 compiled its scripts into `precompiled.rsblob` ("all scripts local with some `@replaceMethod` annotations", its changelog). The blob's name table carries a copy of the game's `CR4MapMenu.UpdateEntityPins` body (`GetMapPinInstances`, the skipped types `NPC` to `HorseRaceDummy`, `User1` to `User7`, the `mq7024_*` tags, `AddPinTypeData`, `PushBackFlashObject`), the keys `map_location_arddhustable` and `map_description_arddhustable`, `W3MerchantComponent`, `EMerchantMapPinType`, `EMMPT_Stable` and `Stables`, and ends with the method names `UpdateEntityPins`, `ApplyHorseUpdateOnSpawn`, `ShouldDisplayHudUpdateByType`, `GetDiscoverableMapPinTypes`, `GetMapPinType`, `ShouldTickInIdle` and `OnTick`. Read as names only (the blob's format is not documented), that means The Stable takes over `CR4MapMenu.UpdateEntityPins` to write its stable masters' names and descriptions on their pins, and maps its merchants' new `EMMPT_Stable` to the `Stables` pin type. Neither needs anything from CMF.

What it means for CMF, with or without this adapter: CMF wraps `CR4MapMenu.UpdateEntityPins` (to open its per-pin list) and `AddPinTypeData` (to write its pin fields). The Stable's copy still calls `AddPinTypeData`, so CMF's pin fields reach every entity pin. CMF's `UpdateEntityPins` wrapper still runs around The Stable's replacement: the big test's log had no `reason=late` lines (Status, below). That question belongs to The Stable together with CMF, not to the adapter, which has no `CR4MapMenu` code.

## How it works

| The Stable's map | Under CMF, through the adapter | CMF version |
|---|---|---|
| `Stables` row under NPCs at 516 | `CMFRegister("modArdDhuStable", 6, 'Stables', '', "NPCs", 516)` (`Stables` has no row in the game's legend, so CMF may place it) | 2 |
| the game's Stables marker | nothing: CMF's map draws the game's own frame | - |
| the row's label | nothing: the legend takes the pins' own label, as in the game | - |

The row is registered once from a `CR4Game.OnGameStarted` wrapper after `CMFRequireVersion("modArdDhuStable", 2)`.

**Provider and claim order.** The claim names `modArdDhuStable`, The Stable's own folder (N4 spec 7.3). The Community Patch adapter claims the same row with the same value under `mod000CommunityPatch_WorldMap`; ignoring case, `mod000…` sorts before `modarddhustable` (`0` before letters), so Community Patch's claim wins and The Stable's is logged as shadowed, the same order as without CMF, where Community Patch's map file loads over The Stable's. Both values are equal, so every mix of the two adapters gives the same map. The Botanist adapter makes no Stables claim.

**Adds nothing without The Stable.** The Stable's scripts ship precompiled, so the adapter cannot call them to tie itself to The Stable. It asks for the row only when The Stable's own text key `map_location_arddhustable` (from its dlc string tables) resolves: `GetLocStringByKeyExt` returns it not empty and not a `#` placeholder, the test CMF's `CMFLevelLabel` uses for its own key. The game's own Stables markers therefore get no row when only CMF and the adapter are installed (Kyle's rule of 2026-10-21 02:25Z: an adapter gives nothing of its mod unless the mod is installed). Not yet launched.

**When The Stable ships its own CMF support, the player uninstalls this adapter.** Since the adapter already claims under `modArdDhuStable`, the author's own support takes over the same claim and folder order.

**Log.** CMF logs the row: `legend row type=Stables category=NPCs priority=516 provider=modArdDhuStable` (or `provider=mod000CommunityPatch_WorldMap` with Community Patch's adapter installed). The adapter adds no log line of its own; it makes one claim and CMF already reports it.

## Known differences

None. The Stable's map changes one row, and CMF gives it back with the same category and priority.

## Files

| Path | What |
|---|---|
| `modCMFAdapterTheStable/content/scripts/local/modcmfadapterthestable_cmf.ws` | the `OnGameStarted` wrapper |
| `modCMFAdapterTheStable/README.txt` | for players |
| `tests/test_cmf_the_stable_adapter.py` | static checks: the one claim matches The Stable's map file and names its folder, it equals the Community Patch adapter's Stables claim, Community Patch's folder sorts first, no art and no pin-field writes, the pack builds |

Build: `python tools/cmf_pack.py build source/adapters/the-stable/modCMFAdapterTheStable --adapts modArdDhuStable --out <new folder>`.

## Status

Static checks pass. Passed in game on 2026-10-20/21 (big test, launches 1 and 1b, CMF API version 6, without Community Patch): the log showed `claims=1 won=1` for `modArdDhuStable`, the row line `legend row type=Stables category=NPCs priority=516 provider=modArdDhuStable` and no `rejected` or `reason=late` lines; in game the horseshoe showed on the map and the minimap with The Stable's own name and description once Geralt had been to the Novigrad stable master (by the Southern Gate signpost), and unticking and ticking the Stables row under NPCs hid it and brought it back. That also settles the open question above: CMF's `UpdateEntityPins` wrapper still runs with The Stable's replacement. Staged pack: a launch record kept in the private development repository.

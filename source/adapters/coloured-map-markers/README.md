# Coloured Map Markers adapter

`modCMFAdapterColouredMapMarkers` brings Coloured Map Markers' coloured world map icons back while Conjunction Map Framework (CMF) draws the world map. Coloured Map Markers (Nexus 938, 1.60) is by DJ_Kovrik and maintained by LewisElementary. Its pictures ship here because the mod's own compatibility notice gives the permission: a sticky, locked post on its Nexus page, "About Compatiblity!" (LewisElementary, 2026-10-12), shares its raw "Shape" icons in the misc files and says "You have permission as long as you credit DJ_Kovrik and the mod". DJ_Kovrik pointed Kyle to that post when he asked. This meets Kyle's rule of 2026-10-21 15:12Z: an author's real art ships in an adapter only with explicit permission, credited.

## Why it also works without Coloured Map Markers

Coloured Map Markers 1.60 is a map-file-only mod: `mods/modcoloured_map_marker/content/blob0.bundle` holds `panel_worldmap.redswf` and `hud_minimap2.redswf` (and its fonts), with no scripts. With CMF installed the game loads CMF's world map, so its world map icons stop showing; its minimap file still loads. Nothing in a script can check that a map-file-only mod is installed, so this adapter cannot require it the way Kyle's adapter rule (2026-10-21 02:25Z) asks of the others. The permission covers using the shapes on their own, and the README says plainly that the icons show with or without Coloured Map Markers. Kyle chose to present it as an adapter all the same (2026-10-21 17:16Z): it is the one adapter that also works alone.

## Provenance

- **Art.** `CMM Shapes - Remastered 938 1.60 2026-10-12T17-16Z CvjFPsr1b.zip` (SHA-256 `0557c9b8fa89e54680a499fe7c9dca914fcc98f3539746322a8e694fad36d218`), Coloured Map Markers' misc download, saved by Kyle in his project folder's `source/compatability-candidates/` and read only. Its `Shape (Worldmap)/shapes/<id>.svg` files are FFDec shape exports named by character id in the world map movie. Nothing was taken from Coloured Map Markers' map file.
- **Which id is which pin type.** Read from the frame labels of the stock pin glyph sprite (`PinIcon_122`, sprite 588) in CMF 1.0.0's map movie, whose sprite tag is pinned byte-identical to vanilla 5.01 (`tools/cmf_pin_types.py`). Every id the adapter uses is the one shape a pin type's frame draws (a 100 × 100 red box, shape 4, is a mask in some frames and not drawn).
- **Left out.** The `_1` to `_3` level shapes (37, 378, 385, 460, 467, 475, 479, 482, 27): API version 1 keys level variants on the base name. Types the map never draws or that 5.01 never sends: `Teleport` 432, `Rift` 442, `Cave` 445, `WitcherHouse` 560, `HiverNestDisabled` 576. Shapes outside the pin glyph: 2, 5, 11, 17, 23, 289, 293, 295 (exported legend classes such as `classWineContract`), 353 (pin radius) and 651 (quest tracker). The minimap shapes are not used.
- **Drawing.** `node tools/cmf_coloured_map_markers_art.js "<zip>/CMM Outlines Shapes - Remastered/Shape (Worldmap)/shapes"` draws each SVG unchanged in headless Chromium, centred into 96 × 96 with the outer 4 pixels clear. `tools/cmf_pack.py` cooks them into the adapter's own `content/texture.cache`.

## Pin types

Each gets one `CMFRegisterIcon`; the legend row takes the same picture. Claims name `modcoloured_map_marker`, Coloured Map Markers' own folder (N4 spec 7.3), so folder order between map mods is the same with CMF as without it.

| Pin type | Shape id | Picture |
|---|---|---|
| `Boat` | 362 | `boat.png` |
| `Horse` | 363 | `horse.png` |
| `Shopkeeper` | 364 | `shopkeeper.png` |
| `Blacksmith` | 365 | `blacksmith.png` |
| `Armorer` | 366 | `armorer.png` |
| `Hairdresser` | 368 | `hairdresser.png` |
| `Alchemic` | 369 | `alchemic.png` |
| `Enchanter` | 370 | `enchanter.png` |
| `PlayerStash` | 374 | `player_stash.png` |
| `PlayerStashDiscoverable` | 374 | `player_stash.png` |
| `Entrance` | 375 | `entrance.png` |
| `MonsterNest` | 376 | `monster_nest.png` |
| `MonsterNestDisabled` | 391 | `monster_nest_disabled.png` |
| `PlaceOfPower` | 393 | `place_of_power.png` |
| `PlaceOfPowerDisabled` | 394 | `place_of_power_disabled.png` |
| `MagicLamp` | 400 | `magic_lamp.png` |
| `Herbalist` | 401 | `herbalist.png` |
| `TreasureHuntMappin` | 409 | `treasure_hunt_mappin.png` |
| `TreasureHuntMappinDisabled` | 424 | `treasure_hunt_mappin_disabled.png` |
| `Whetstone` | 428 | `whetstone.png` |
| `ArmorRepairTable` | 429 | `armor_repair_table.png` |
| `GrindStone` | 431 | `grind_stone.png` |
| `Prostitute` | 435 | `prostitute.png` |
| `Innkeeper` | 444 | `innkeeper.png` |
| `SpoilsOfWar` | 457 | `spoils_of_war.png` |
| `SpoilsOfWarDisabled` | 458 | `spoils_of_war_disabled.png` |
| `BanditCamp` | 459 | `bandit_camp.png` |
| `BanditCampDisabled` | 471 | `bandit_camp_disabled.png` |
| `BanditCampfire` | 472 | `bandit_campfire.png` |
| `BanditCampfireDisabled` | 473 | `bandit_campfire_disabled.png` |
| `BossAndTreasure` | 474 | `boss_and_treasure.png` |
| `BossAndTreasureDisabled` | 486 | `boss_and_treasure_disabled.png` |
| `Contraband` | 487 | `contraband.png` |
| `ContrabandDisabled` | 488 | `contraband_disabled.png` |
| `ContrabandShip` | 489 | `contraband_ship.png` |
| `ContrabandShipDisabled` | 490 | `contraband_ship_disabled.png` |
| `RescuingTown` | 491 | `rescuing_town.png` |
| `RescuingTownDisabled` | 509 | `rescuing_town_disabled.png` |
| `DungeonCrawl` | 510 | `dungeon_crawl.png` |
| `DungeonCrawlDisabled` | 511 | `dungeon_crawl_disabled.png` |
| `Hideout` | 512 | `hideout.png` |
| `HideoutDisabled` | 514 | `hideout_disabled.png` |
| `Archmaster` | 520 | `archmaster.png` |
| `InfestedVineyard` | 522 | `infested_vineyard.png` |
| `InfestedVineyardDisabled` | 526 | `infested_vineyard_disabled.png` |
| `WineMerchant` | 527 | `wine_merchant.png` |
| `DyeMerchant` | 529 | `dye_merchant.png` |
| `Plegmund` | 533 | `plegmund.png` |
| `PlegmundDisabled` | 535 | `plegmund_disabled.png` |
| `WineContract` | 536 | `wine_contract.png` |
| `WineContractDisabled` | 537 | `wine_contract_disabled.png` |
| `SignalingStake` | 539 | `signaling_stake.png` |
| `SignalingStakeDisabled` | 540 | `signaling_stake_disabled.png` |
| `Stables` | 541 | `stables.png` |
| `Bed` | 543 | `bed.png` |
| `MutagenDismantle` | 545 | `mutagen_dismantle.png` |
| `AlchemyTable` | 546 | `alchemy_table.png` |
| `Bookshelf` | 550 | `bookshelf.png` |
| `KnightErrant` | 552 | `knight_errant.png` |
| `KnightErrantDisabled` | 554 | `knight_errant_disabled.png` |
| `Cammerlengo` | 556 | `cammerlengo.png` |

## Files

| Path | What |
|---|---|
| `modCMFAdapterColouredMapMarkers/content/scripts/local/modcmfadaptercolouredmapmarkers_cmf.ws` | 61 `CMFRegisterIcon` calls under `CMFRequireVersion(…, 1)` |
| `modCMFAdapterColouredMapMarkers/art/*.png` | 60 pictures (`PlayerStash` and `PlayerStashDiscoverable` share one) |
| `modCMFAdapterColouredMapMarkers/README.txt` | For players, with the credit |
| `tools/cmf_coloured_map_markers_art.js` | The shape id table and the drawing |
| `tests/test_cmf_coloured_map_markers_adapter.py` | Static checks: every type is a drawn 5.01 type, one 96 picture per shape, every claim names `modcoloured_map_marker`, the credit is in the README and the script, the adapter builds |

Build: `python tools/cmf_pack.py build source/adapters/coloured-map-markers/modCMFAdapterColouredMapMarkers --adapts modcoloured_map_marker --out <new folder>`. One warning: `bookshelf.png` shifts colour a little when compressed. Launched 2026-10-21 with Coloured Map Markers 1.60 and without it.

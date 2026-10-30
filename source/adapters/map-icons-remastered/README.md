# Map Icons - Remastered pack 1.0.0

`modCMFAdapterMapIconsRemastered` brings Map Icons - Remastered's world map icons and its seven flat region emblems to Conjunction Map Framework's (CMF's) map. Map Icons - Remastered ([Nexus 14490](https://www.nexusmods.com/witcher3/mods/14490), 1.0) is by [kandy422](https://www.nexusmods.com/profile/kandy422), who gave explicit permission on 2026-10-30 to use the art of their mods in CMF adapters, with credit. Kyle confirmed that the permission covers the art itself.

## Why it also works without Map Icons - Remastered

Map Icons - Remastered is a map-file-only mod: its icons live in its own copy of the world map file, which does not load while CMF draws the map, and it has no script or setting that another mod could check. So, like the Coloured Map Markers adapter, this pack cannot require the mod, and the pictures show with or without Map Icons installed. Map Icons - Remastered stays its Nexus requirement. Its claims name the mod's own folder, `mod000MapIconsRemastered`, so the order between map mods stays what it would be without CMF, and CMF's menu shows it as "Map Icons Remastered". The Adapter Check add-on cannot see the mod, so it never warns about it; the offline list checker names this pack.

## Provenance

Archive: `Map Icons Remastered 1.0 14490 1.0 2026-10-17T07-55Z Ukn0RyUM2.zip`.

- Archive SHA-256: `15c9699330777a2291a758a49db58996aeaa59f3c1473358888f6264bd1f3b0e`.
- World map resource SHA-256: `d994af5bd2d58017fe6c1b0e1fd40ffc381e5139788113cadda4071ed2e680c1`.
- Movie SHA-256: `4e49fe606567f6d8e193b0f26ae68cdfd5015ce6183f063a097c44f3f01beb1e`.
- `art-manifest.json` records every original bitmap, frame, fitted PNG hash and emblem crop; `labels.csv` is the complete table of the mod's icon states.

Only Map Icons' unsuffixed world map states are used (its second bank holds the same drawings). All 143 visible states are extracted and 138 ship. Each picture is kandy422's bitmap unchanged: cropped to its drawn pixels (including its faint glow), fitted within 88 x 88 and centred on a clear 96 x 96 canvas, as CMF fits the whole canvas into the game icon's box. Nothing is recoloured, redrawn or added. The completed (`...Disabled`) pictures are drawn much darker than the active ones, and the pack keeps them that way.

The source resource's header counts 6 exports but its table holds 21; the tool checks every original checksum and hash, reads all 21, and never rewrites the source.

## API gates and legend behaviour

109 ordinary icons use API 1. The 21 level variants and Player/User1-User7 use `CMFGetVersion() >= 11` (CMF 1.5.0). Seven crests use generic property 25 inside `>= 9` (CMF 1.3.0), avoiding an API 9-only named function reference on older cores. Calls use only public functions available from API 1. Static/source checks do not prove engine compilation.

Each icon call supplies that type's legend image automatically. Completed types have their own original image; no `CMFRegisterDisabled` call is used. Quest types keep distinct pictures as requested; the existing shared quest legend row shows the picture of whichever quest is added first. The pack checker warns about this and all 20 historical reach=unknown entries; those advisories are recorded individually, without editing the shared table. Other map mods can send the stock-only types, so they are deliberately registered.

## Complete source-label disposition

| Label / type | Frame | API floor | Picture or exclusion |
|---|---:|---:|---|
| `RoadSign` | 1 | 1 | art/road_sign.png |
| `Quest` | 11 | 1 | art/quest.png |
| `Boat` | 21 | 1 | art/boat.png |
| `Horse` | 31 | 1 | art/horse.png |
| `Shopkeeper` | 41 | 1 | art/shopkeeper.png |
| `Blacksmith` | 51 | 1 | art/blacksmith.png |
| `Armorer` | 61 | 1 | art/armorer.png |
| `BoatBuilder` | 71 | 1 | art/boat_builder.png |
| `Hairdresser` | 81 | 1 | art/hairdresser.png |
| `Alchemic` | 91 | 1 | art/alchemic.png |
| `Enchanter` | 101 | 1 | art/enchanter.png |
| `Container` | 111 | 1 | art/container.png |
| `NoticeBoardFull` | 121 | 1 | art/notice_board_full.png |
| `NoticeBoard` | 131 | 1 | art/notice_board.png |
| `PlayerStash` | 141 | 1 | art/player_stash.png |
| `PlayerStashDiscoverable` | 151 | 1 | art/player_stash_discoverable.png |
| `Entrance` | 162 | 1 | art/entrance.png |
| `MonsterNest` | 172 | 1 | art/monster_nest.png |
| `MonsterNest_1` | 182 | 11 | art/monster_nest_1.png |
| `MonsterNest_2` | 192 | 11 | art/monster_nest_2.png |
| `MonsterNest_3` | 202 | 11 | art/monster_nest_3.png |
| `MonsterNestDisabled` | 212 | 1 | art/monster_nest_disabled.png |
| `MonsterHunt` | 222 | 1 | art/monster_hunt.png |
| `PlaceOfPower` | 232 | 1 | art/place_of_power.png |
| `PlaceOfPowerDisabled` | 242 | 1 | art/place_of_power_disabled.png |
| `Enemy` | 252 | - | Excluded: vanilla filters this type before world-map emission |
| `EnemyDead` | 262 | - | Excluded: vanilla filters this type before world-map emission |
| `Harbor` | 272 | 1 | art/harbor.png |
| `MagicLamp` | 282 | 1 | art/magic_lamp.png |
| `Herbalist` | 292 | 1 | art/herbalist.png |
| `Player` | 302 | 11 | art/player.png |
| `racetrack` | 312 | 1 | art/racetrack.png |
| `QuestAvailable` | 322 | 1 | art/quest_available.png |
| `QuestAvailableHoS` | 332 | 1 | art/quest_available_ho_s.png |
| `QuestAvailableBaW` | 342 | 1 | art/quest_available_ba_w.png |
| `StoryQuest` | 352 | 1 | art/story_quest.png |
| `ChapterQuest` | 362 | 1 | art/chapter_quest.png |
| `SideQuest` | 372 | 1 | art/side_quest.png |
| `MonsterQuest` | 382 | 1 | art/monster_quest.png |
| `TreasureQuest` | 392 | 1 | art/treasure_quest.png |
| `TreasureHuntMappin` | 402 | 1 | art/treasure_hunt_mappin.png |
| `TreasureHuntMappin_1` | 412 | 11 | art/treasure_hunt_mappin_1.png |
| `TreasureHuntMappin_2` | 422 | 11 | art/treasure_hunt_mappin_2.png |
| `TreasureHuntMappin_3` | 432 | 11 | art/treasure_hunt_mappin_3.png |
| `TreasureHuntMappinDisabled` | 442 | 1 | art/treasure_hunt_mappin_disabled.png |
| `MonsterClue` | 452 | 1 | art/monster_clue.png |
| `Camp` | 462 | 1 | art/camp.png |
| `DwarvenFurnace` | 472 | 1 | art/dwarven_furnace.png |
| `Whetstone` | 482 | 1 | art/whetstone.png |
| `ArmorRepairTable` | 492 | 1 | art/armor_repair_table.png |
| `BoatRace` | 502 | 1 | art/boat_race.png |
| `GrindStone` | 512 | 1 | art/grind_stone.png |
| `Teleport` | 522 | - | Excluded: vanilla filters this type before world-map emission |
| `PlaceOfPowerStrong` | 532 | 1 | art/place_of_power_strong.png |
| `FistFight` | 542 | 1 | art/fist_fight.png |
| `GenericFocus` | 552 | - | Excluded: vanilla filters this type before world-map emission |
| `Companion` | 562 | 1 | art/companion.png |
| `Prostitute` | 572 | 1 | art/prostitute.png |
| `QuestReturn` | 582 | - | Excluded: empty source frame |
| `QuestGiverStory` | 592 | 1 | art/quest_giver_story.png |
| `QuestGiverChapter` | 602 | 1 | art/quest_giver_chapter.png |
| `QuestGiverSide` | 612 | 1 | art/quest_giver_side.png |
| `HorseRacingNPC` | 622 | 1 | art/horse_racing_npc.png |
| `HorseRace` | 632 | 1 | art/horse_race.png |
| `NonQuestHorseRace` | 642 | 1 | art/non_quest_horse_race.png |
| `QuestBelgard` | 652 | 1 | art/quest_belgard.png |
| `QuestCoronata` | 662 | 1 | art/quest_coronata.png |
| `QuestVermentino` | 672 | 1 | art/quest_vermentino.png |
| `Rift` | 682 | - | Excluded: vanilla filters this type before world-map emission |
| `User1` | 692 | 11 | art/user1.png |
| `User2` | 702 | 11 | art/user2.png |
| `User3` | 712 | 11 | art/user3.png |
| `User4` | 722 | 11 | art/user4.png |
| `Herb` | 732 | 1 | art/herb.png |
| `Innkeeper` | 742 | 1 | art/innkeeper.png |
| `Cave` | 752 | 1 | art/cave.png |
| `NotDiscoveredPOI` | 762 | 1 | art/not_discovered_poi.png |
| `NotDiscoveredPOI_1` | 772 | 11 | art/not_discovered_poi_1.png |
| `NotDiscoveredPOI_2` | 782 | 11 | art/not_discovered_poi_2.png |
| `NotDiscoveredPOI_3` | 792 | 11 | art/not_discovered_poi_3.png |
| `SpoilsOfWar` | 802 | 1 | art/spoils_of_war.png |
| `SpoilsOfWarDisabled` | 812 | 1 | art/spoils_of_war_disabled.png |
| `BanditCamp` | 822 | 1 | art/bandit_camp.png |
| `BanditCamp_1` | 832 | 11 | art/bandit_camp_1.png |
| `BanditCamp_2` | 842 | 11 | art/bandit_camp_2.png |
| `BanditCamp_3` | 852 | 11 | art/bandit_camp_3.png |
| `BanditCampDisabled` | 862 | 1 | art/bandit_camp_disabled.png |
| `BanditCampfire` | 872 | 1 | art/bandit_campfire.png |
| `BanditCampfireDisabled` | 882 | 1 | art/bandit_campfire_disabled.png |
| `BossAndTreasure` | 892 | 1 | art/boss_and_treasure.png |
| `BossAndTreasure_1` | 902 | 11 | art/boss_and_treasure_1.png |
| `BossAndTreasure_2` | 912 | 11 | art/boss_and_treasure_2.png |
| `BossAndTreasure_3` | 922 | 11 | art/boss_and_treasure_3.png |
| `BossAndTreasureDisabled` | 932 | 1 | art/boss_and_treasure_disabled.png |
| `Contraband` | 942 | 1 | art/contraband.png |
| `ContrabandDisabled` | 952 | 1 | art/contraband_disabled.png |
| `ContrabandShip` | 962 | 1 | art/contraband_ship.png |
| `ContrabandShipDisabled` | 972 | 1 | art/contraband_ship_disabled.png |
| `RescuingTown` | 982 | 1 | art/rescuing_town.png |
| `RescuingTown_1` | 992 | 11 | art/rescuing_town_1.png |
| `RescuingTown_2` | 1002 | 11 | art/rescuing_town_2.png |
| `RescuingTown_3` | 1012 | 11 | art/rescuing_town_3.png |
| `RescuingTownDisabled` | 1022 | 1 | art/rescuing_town_disabled.png |
| `DungeonCrawl` | 1032 | 1 | art/dungeon_crawl.png |
| `DungeonCrawlDisabled` | 1042 | 1 | art/dungeon_crawl_disabled.png |
| `Hideout` | 1052 | 1 | art/hideout.png |
| `HideoutDisabled` | 1062 | 1 | art/hideout_disabled.png |
| `Torch` | 1072 | 1 | art/torch.png |
| `Archmaster` | 1082 | 1 | art/archmaster.png |
| `InfestedVineyard` | 1092 | 1 | art/infested_vineyard.png |
| `InfestedVineyard_1` | 1103 | 11 | art/infested_vineyard_1.png |
| `InfestedVineyard_2` | 1113 | 11 | art/infested_vineyard_2.png |
| `InfestedVineyard_3` | 1123 | 11 | art/infested_vineyard_3.png |
| `InfestedVineyardDisabled` | 1133 | 1 | art/infested_vineyard_disabled.png |
| `WineMerchant` | 1144 | 1 | art/wine_merchant.png |
| `DyeMerchant` | 1155 | 1 | art/dye_merchant.png |
| `Plegmund` | 1166 | 1 | art/plegmund.png |
| `PlegmundDisabled` | 1177 | 1 | art/plegmund_disabled.png |
| `WineContract` | 1188 | 1 | art/wine_contract.png |
| `WineContractDisabled` | 1199 | 1 | art/wine_contract_disabled.png |
| `SignalingStake` | 1210 | 1 | art/signaling_stake.png |
| `SignalingStakeDisabled` | 1220 | 1 | art/signaling_stake_disabled.png |
| `Stables` | 1230 | 1 | art/stables.png |
| `Bed` | 1241 | 1 | art/bed.png |
| `MutagenDismantle` | 1252 | 1 | art/mutagen_dismantle.png |
| `AlchemyTable` | 1263 | 1 | art/alchemy_table.png |
| `Bookshelf` | 1274 | 1 | art/bookshelf.png |
| `KnightErrant` | 1285 | 1 | art/knight_errant.png |
| `KnightErrantDisabled` | 1296 | 1 | art/knight_errant_disabled.png |
| `Cammerlengo` | 1307 | 1 | art/cammerlengo.png |
| `WitcherHouse` | 1318 | 1 | art/witcher_house.png |
| `LettenStories` | 1330 | 1 | art/letten_stories.png |
| `NettelStories` | 1342 | 1 | art/nettel_stories.png |
| `LettenStoriesDisabled` | 1354 | 1 | art/letten_stories_disabled.png |
| `NettelStoriesDisabled` | 1366 | 1 | art/nettel_stories_disabled.png |
| `Transport` | 1378 | 1 | art/transport.png |
| `HiverNest` | 1390 | 1 | art/hiver_nest.png |
| `HiverNestDisabled` | 1402 | 1 | art/hiver_nest_disabled.png |
| `QuestAvailableLy` | 1414 | 1 | art/quest_available_ly.png |
| `QuestObjective` | 1424 | 1 | art/quest_objective.png |
| `QuestObjectiveOther` | 1434 | 1 | art/quest_objective_other.png |
| `User5` | 1444 | 11 | art/user5.png |
| `User6` | 1454 | 11 | art/user6.png |
| `User7` | 1464 | 11 | art/user7.png |

## Seven region emblems

Map Icons' own `PinIcon_122.redesigned` defaults true; UniverseArea/UniverseMap select unsuffixed inactive/active through SelectFrame. Its archive has no script override. These are the same flat drawings retained, but switched off, in Map Remastered 2.4.2. The prior read also found that Map Remastered's retained Original_ bitmap crops differ from vanilla; no byte-identical-vanilla claim is made. The empty Custom sprite is not packaged.

Full source crop rectangles, not trimmed screenshots, are resized to the world-art guide's BC3-compatible sizes. CMF fits them to the native 135 x 116 rectangle (135 x 130 for Kaer Morhen).

| Region | PNG size | Picture |
|---|---|---|
| `bob` | 136 x 116 | `art/world/crest_bob.png` |
| `prolog_village` | 136 x 116 | `art/world/crest_prolog_village.png` |
| `skellige` | 136 x 116 | `art/world/crest_skellige.png` |
| `kaer_morhen` | 136 x 132 | `art/world/crest_kaer_morhen.png` |
| `novigrad` | 136 x 116 | `art/world/crest_novigrad.png` |
| `no_mans_land` | 136 x 116 | `art/world/crest_no_mans_land.png` |
| `wyzima_castle` | 136 x 116 | `art/world/crest_wyzima_castle.png` |

## Minimap scope

No original minimap artwork is imported. This pack replaces no HUD movie. With Map Icons installed, its own minimap still loads and keeps its look, as long as no other mod's minimap file wins over it. Without Map Icons, the optional CMF Minimap Add-on can reuse this pack's world icons by type. It does not become the source mod's separate minimap set.

## Reproduce and build

Use Python 3.12 with Pillow 12.3.0/lz4 4.4.4 and the qualified Java/FFDec 26.3.0. Supply paths; the tool has no machine-specific path defaults.

```text
python -B tools/cmf_map_icons_remastered_art.py <source-archive> --java <java> --ffdec <ffdec.jar> --out <new-extraction-directory>
python -B tools/cmf_pack.py check source/adapters/map-icons-remastered/modCMFAdapterMapIconsRemastered --adapts mod000MapIconsRemastered
python -B tools/cmf_pack.py build source/adapters/map-icons-remastered/modCMFAdapterMapIconsRemastered --adapts mod000MapIconsRemastered --out <new-package-directory>
```

The extraction writes all 143 `art/*.png`, seven `art/world/*.png`, labels.csv, manifest.json and local work files. Select only rows with `included=true` plus the seven crests for this source pack. Wrong hashes/topology fail; an existing output directory is refused. Failure after output creation leaves FAILED.txt and no success manifest. Two fresh qualified extractions were byte-identical. The built Mods tree contains only README.txt, one local startup script and texture.cache.

Tests: `tests/test_cmf_map_icons_remastered_adapter.py` runs the actual startup script at API 0, 1, 8, 9, 10 and 11 and checks the art, every claim and the package (it needs the private read evidence, so it is not in the public repository).

Launched on 2026-10-30 on Windows with keyboard and mouse, in the usual 28-mod test set with CMF 1.6.3 and without Map Icons installed: all 145 claims (138 icons and 7 emblems) won, the shop, service and completed icons, the legend rows and the seven flat emblems on the world overview showed the pack's pictures, and the log had no error from CMF or the pack. Not tested: a controller, beside Map Icons - Remastered itself, Vortex and Mod Organizer 2, Steam Deck, Linux (Proton).

Made by Kyle with the help of AI tools (Claude and ChatGPT)

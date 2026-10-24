# Adapter catalogue evidence - 2026-10-24

This is a fact/provenance record for tools/cmf_adapter_list.json. It is not a runtime test or a claim about the current installed mod set. No reference code or assets were extracted or copied into the product.

## Classification and tested-version authority

Primary: https://www.nexusmods.com/witcher3/mods/14693, section "Mods that need no adapter", retrieved/verified 2026-10-24 by the controller evidence worker. The supplied execution evidence is .superpowers/sdd/2026-10-24-missing-adapter-detection/public-compile-evidence.md. The approved task-3-brief.md pins the complete table below.

Secondary: https://github.com/KyleCo76/Conjunction-Map-Framework#supported-map-mods (public README, shorter matching list, checked 2026-10-24 in the supplied evidence). All 11 rows below use the primary list; no inferred coexistence or source-only paragraph was substituted. This worker used that supplied verification rather than repeating the same web retrieval.

| Public name | Nexus ID | Tested version | Folder | Exact authority |
| --- | --- | --- | --- | --- |
| Map Remastered | 13347 | 2.4.2 | modmapredraw | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| All Quest Markers | 13087 | 1.7.1 | modAllQuestMarkersOnMapRemaster | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| Quest Levels on Map | 13691 | 1 | modMapQuestLevels | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| Useful Place of Power Map Pin | 11300 | 1.2 | modUsefulPOPMapPin | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| True Map POIs | 13213 | 1.0.3 | modtruemappois | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| RevealMapPOI | 13140 | 1.0.4 | modRevealMapPOI | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| Reveal Map Icons - Remastered | 13516 | 1.0.1 | modRevealMapIcons | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| Wolf's Bearing | 14546 | 1.0 | modWolfsBearing | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| Wild Monster Hunt | 9426 | 2.1 | modwild_monster_hunt | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| Apocrypha Menu Framework | 13656 | 1.0.6 | modApocryphaMenuFramework | Nexus 14693, Mods that need no adapter, 2026-10-24 |
| HUD Position Manager | 14337 | 1.0.0 | modHUDPositionManager | Nexus 14693, Mods that need no adapter, 2026-10-24 |

Map Remastered 2.4.2 is a works entry under this public list, superseding the older author-update research classification. Wolf's Bearing 1.1 is code checked only; the tested entry is 1.0. RevealMapPOI and Reveal Map Icons require All or Exploration filtering. Wild Monster Hunt also ships dlcwild_monster_hunt.

## Adapter identities and detectors

Authority: the build handoff and research record kept in the private development repository, and source/adapters/<adapter>/README.md plus the matching README.txt/script provider strings at base 307c9ce7d84bac17da827192a00d8a5eb2450350. Adapter file labels follow the public "CMF Adapter - <mod name>" label; folder names below are the existing folders, not newly distributed packages.

| Mod | Accepted provider(s) | Group alternatives | Text alternatives | Adapter folder / download label |
| --- | --- | --- | --- | --- |
| Map Quest Insight | modMapQuestInsight | qmiPins, qmiColors, qmiBox, qmiHide, qmiWide | panel_qmiPins | modCMFAdapterMapQuestInsight / CMF Adapter - Map Quest Insight |
| Gwent Players Map | modGwentPlayersMap | GwentPlayersMap | gwm_label_gwent_player | modCMFAdapterGwentPlayersMap / CMF Adapter - Gwent Players Map |
| Witcher Gear Map | modWitcherGearMap | wgm_Settings | wgm_legendary | modCMFAdapterWitcherGearMap / CMF Adapter - Witcher Gear Map |
| Fog of War | modFogOfWar | FogOfWar | option_fow_enabled | modCMFAdapterFogOfWar / CMF Adapter - Fog of War |
| Witcher's Path | modWitchersPath | WitchersPath | option_wp_enabled | modCMFAdapterWitchersPath / CMF Adapter - Witcher's Path |
| Botanist | modBotanist | Botanist_GeneralSettings | BT_HerbMapPinInfo | modCMFAdapterBotanist / CMF Adapter - Botanist |
| Ink and Iron | modInkAndIronUI | InkAndIronOptions | panel_InkAndIron | modCMFAdapterInkAndIron / CMF Adapter - Ink and Iron |
| The Stable | modArdDhuStable | none | map_location_arddhustable | modCMFAdapterTheStable / CMF Adapter - The Stable |
| All Quest Objectives | modAQOOMRemastered | none | none | modCMFAdapterAllQuestObjectives / CMF Adapter - All Quest Objectives |
| Map Pin Teleport | modMapPinTeleport | none | none | modCMFAdapterMapPinTeleport / CMF Adapter - Map Pin Teleport |
| Annoying Map | modAnnoyingMap | none | none | modCMFAdapterAnnoyingMap / CMF Adapter - Annoying Map |
| Coloured Map Markers | modcoloured_map_marker | none | none | modCMFAdapterColouredMapMarkers / CMF Adapter - Coloured Map Markers |

Populated detector categories combine with AND; alternatives within a category combine with OR. Only the first eight adapter rows have detectors. The other four adapter rows are page-only. Ink and Iron matches both modInkAndIron and modInkAndIronUI on the page; its established provider remains modInkAndIronUI. The two source aliases are recorded by source/adapters/ink-and-iron/README.md; current All In One archive confirms modInkAndIron.

Fog of War minimum 1.0.1 and Map Quest Insight minimum 1.1.1 are the user-approved recommended downloads after their startup-presence fix. A missing provider does not measure an installed adapter version. Both consumers say install or update the named file (version X or newer). No other adapter version is changed.

Smooth Map and Community Patch - World Map are author-update page entries with adapter=null, empty groups/textKeys, and no in-game table row. Smooth Map uses the handoff's exact note. Map Icons Remastered is author-update only, with its actual mod000MapIconsRemastered archive folder. Coloured Map Markers retains its separate art adapter and no in-game detector. World Map Merger is an incompatible external tool: exact-name match only, no evidenced Nexus URL/folder and no invented link.

## Read-only archive identities

Archives remain in the manager checkout. Below are SHA-256 values calculated 2026-10-24 and folder names read from ZIP central directories only. For the 7z input, the folder comes from the approved evidence table rather than a new extraction. Archive versions establish identifier provenance only; tested-with-CMF versions come from the public table above.

| Name | Exact archive path | SHA-256 | Directory identity |
| --- | --- | --- | --- |
| Map Quest Insight | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\MapQuestInsight-1.6.2 14219 1.6.2 2026-10-21T20-40Z cYAe9qcaG.zip | c968c8a36856cecea633dfca6d6b50ff41a1995cad0f6fc23e7aef373cb3568f | modMapQuestInsight |
| Gwent Players Map | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Gwent Players Map (1.0.9) 13755 1.0.9 2026-10-15T20-21Z 864tMl8q0.zip | bd72b19d8b8dcbdf77a5065eec18b6bae970c544d641ad3984807c82ce378f00 | modGwentPlayersMap |
| Witcher Gear Map | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\WitcherGearMap 14157 1.0.1 2026-10-12T11-20Z FLZ3sa9zo.zip | 44fcaa56ebfa731a4a453a815556266b737b4019f52ae8f6a510e9051746b334 | modWitcherGearMap |
| Fog of War | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\FogOfWar (5.01) 13627 1.2.1 2026-10-08T22-58Z LKqTerUTH.zip | 96ff2022a7a0cdcb56121386f0b6a38ce9ca534bd152ccf7306d0051908e5d79 | modFogOfWar |
| Witcher's Path | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Witcher's Path (5.01) 13423 1.0.3 2026-10-12T19-53Z CvjFPsr7Z.zip | 0615f2aa21d78d910a22cfb32fcd5617a9cb724e25a711a2719bcad5fec56b6d | modWitchersPath |
| Botanist | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Botanist - Remastered 8260 3.0.0.2 2026-10-15T22-47Z CvjFPsCcv.zip | 0de49d428e635cdad1a438a881766ee533debb92b52978a19f954a845082710d | modBotanist |
| Ink and Iron | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Ink and Iron - All In One File 13111 0.9.0 2026-10-22T19-00Z 864tMl8wp.zip | a97db50f3f72e2f5f57bd3b26f78e5a63a18c5c2dc3672dc065dde8035a5d1f6 | modInkAndIron |
| The Stable | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\The Stable 6132 2.2.1 2026-10-14T09-59Z DzkABbDNl.zip | 45901e0733e6de3c8a1fd0a5b79043ff4dc0912dd4aaf155cb2f75529ffc8f96 | modArdDhuStable |
| All Quest Objectives | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\All Quest Objectives On Map - Remastered 14319 1.2.1 2026-10-18T10-52Z oDUKYHoAV.zip | 850311922fe812548e9c04e168e40906c0e6cb388e91c11438b9061a15bb95fc | modAQOOMRemastered |
| Map Pin Teleport | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\MapPinTeleport 1.2.2(5.01) 13541 5 2026-10-10T16-44Z iNpQhXlMl.zip | f9fa95db3b3b5af7d2626b5d8618a1e72253fd68e368505de909515a1b4e63f2 | modMapPinTeleport |
| Annoying Map | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Annoying Map (Remastered 5.01) 6140 3.1 2026-10-09T01-35Z KA0dHIkdz.zip | fdbf052cff954fbab3b7b4831ce80393c9c5bc321663cd1475bb4317e1984aa2 | modAnnoyingMap |
| Coloured Map Markers | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Coloured Map Marker - Remastered 938 1.60 2026-10-12T17-21Z YBRHU02oy.zip | 91842e823db6a20e724c93e9b3ab79a5c8e8cb685b12febb47017c89ee671510 | modcoloured_map_marker |
| Smooth Map | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Smooth Map 13530 1.1 2026-10-16T21-23Z sedaZos1e.zip | ca455919aba3ef5152229d62809503d798cb15b91dd81539abe3d9c49870ba24 | modSmoothMap |
| Community Patch - World Map | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Remastered - Vanilla 8259 2.0.0.0 2026-10-11T12-45Z rIB9DAybn.zip | 5012a1ccb0d82514b1f76e589e1b35fe2f5c0aeff4ede415b45d168ef2222de7 | mod000CommunityPatch_WorldMap |
| Map Icons Remastered | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Map Icons Remastered 1.0 14490 1.0 2026-10-17T07-55Z Ukn0RyUM2.zip | 15c9699330777a2291a758a49db58996aeaa59f3c1473358888f6264bd1f3b0e | mod000MapIconsRemastered |
| Map Remastered | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Map and Icons Remastered 13347 2.4.2 2026-10-16T16-38Z 2h8gGW25c.zip | 674e0bf9f6011f9f7d55caf23c7f0b53c820f2d8e8d85c53d05b051c8605015a | modmapredraw |
| All Quest Markers | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\AllQuestMarkersOnMapRemaster 13087 1.7.1 2026-10-18T15-37Z KA0dHIKa2.zip | abb034908cf26346f6ddd22c1725cdf7d1b87c31e44307f4679cbfa9413ab2ae | modAllQuestMarkersOnMapRemaster |
| Quest Levels on Map | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Quest Levels on Map 13691 1 2026-10-06T13-26Z 864tMls6X.zip | 3aaf55b0885c9afdeec87bd79e66541ba97af39438c6b6da0b97743710391aa5 | modMapQuestLevels |
| Useful Place of Power Map Pin | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Useful Place Of Power Map Pin - Remastered 11300 1.2 2026-10-03T19-50Z FLZ3safmr.7z | 9d1099ffa6688ffda1203cf8acdcdd3538bd7adc4fdbf148b0168ff8eead7c9a | modUsefulPOPMapPin (supplied evidence; 7z not extracted) |
| True Map POIs | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\True Map POIs v1.0.3 13213 1.0.3 2026-10-08T12-36Z 5sT4VvK3V.zip | 65de1b6271b54fc79ecabbd18571a3bf9902f313b4fa91b08aa44891de772237 | modtruemappois |
| RevealMapPOI | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\RevealMapPOI Remastered 13140 1.0.4 2026-10-08T18-00Z 9UbqAJfb9.zip | 73d239437725f852907d228fd8956e943f1ca2c58e92757b00c3cef95ff76390 | modRevealMapPOI |
| Reveal Map Icons - Remastered | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\RevealMapIcons Remastered V1.0.1 13516 1.0.1 2026-10-04T20-53Z GpMW8t9uI.zip | 2989158bdac9b5062065f8088645288be7651aee4056e438b6aaf7747a0de073 | modRevealMapIcons |
| Wolf's Bearing | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Wolf's Bearing 1.0 14546 1.0 2026-10-18T01-06Z Jy2BxkJj5.zip | ac99b2057a12d166bb475825d52b321c0f007e97455d6795828007940b9fc8db | modWolfsBearing |
| Wild Monster Hunt | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Wild Monster Hunt - Remastered Compatible 9426 v2.1 2026-10-09T16-31Z mlFpu6vA5.zip | c0937a972863c8388bcf4ccf3328180d551f959b4ddff4d1e2ad911d0d917dbd | modwild_monster_hunt |
| Apocrypha Menu Framework | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\Apocrypha Menu Framework - No Installer 13656 1.0.6 2026-10-16T01-07Z kQW7gSkXJ.zip | ae6d41757e6ad2a85bf2462184c7a3b418f7d99bbb398de137c3154076656e7d | modApocryphaMenuFramework |
| HUD Position Manager | C:\Users\Kyle\Projects\witcher-mods\modConjunctionMapFramework\source\compatability-candidates\HUD Position Manager 14337 1.0.0 2026-10-14T11-37Z hw6Xp1hwV.zip | e0ec72adfe809ebaab279b6d044a4ecc07bfe47e6eabe6192c6ec15195b6c6c7 | modHUDPositionManager |

The canonical catalogue order is append-only: localized mod fragments use 2000200904 + catalogue index, including page-only rows. Reordering or deleting existing entries changes that mapping; future updates append rows and keep older identities reserved. The generated add-on tables use the English fallback in all 18 existing language codes.

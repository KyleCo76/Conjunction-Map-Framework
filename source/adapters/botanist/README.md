# Botanist adapter (proof of concept)

`modCMFAdapterBotanist` is a separate mod that sits between Conjunction Map Framework (CMF) and Botanist - NG - Remastered 3.0.0.2 (Nexus 8260, with Shared Utils 4.1, Nexus 12997). Botanist 3.0 ships its own copy of the game's world map file, which adds a "Botanist" filter tab, three marker rows and three marker drawings. Under CMF that file does not load, because `mod0000_ConjunctionMapFramework` sorts ahead of `modBotanist`. The adapter asks CMF for the same changes through CMF's general calls, adds nothing of its own, and ships only CMF-drawn placeholder art. The author-facing version is [`docs/authors/botanist-adapter.md`](../../../docs/authors/botanist-adapter.md).

## Provenance

Read only on 2026-10-20, from Kyle's downloads (`source/compatability-candidates/` and his Vortex downloads folder):

| Archive | SHA-256 | What it holds |
|---|---|---|
| `Botanist - Remastered 8260 3.0.0.2 2026-10-15T22-47Z CvjFPsCcv.zip` | `0de49d428e635cdad1a438a881766ee533debb92b52978a19f954a845082710d` | `mods/modBotanist/content/` (`blob0.bundle` = `panel_worldmap.redswf` only, `metadata.store`, `texture.cache` with its minimap guide arrows, `precompiled.rsblob` = all its scripts, 17 `.w3strings`, `en.csv`, `info.json` 3.0.0.2) and `bin/config/r4game/user_config_matrix/pc/modBotanist.xml` (its menu); no loose scripts |
| `Sharedutils - All In One 12997 4.1 2026-10-10T15-21Z lPL5EVoZD.zip` | `99808dc59dc3afc7093d29e9753f40f01fae1da8a936c666af9dd80e0dbff167` | `mods/modzzz_sharedutils/` (loose scripts under `scripts/local/sharedutils/`, plus `precompiled.rsblob`) and `dlc/dlcsharedutils/`; no map file |
| `Remastered - Vanilla 8259 2.0.0.0 2026-10-11T12-45Z rIB9DAybn.zip` (Community Patch, for comparison) | `5012a1ccb0d82514b1f76e589e1b35fe2f5c0aeff4ede415b45d168ef2222de7` | as in the Community Patch adapter's README |

Botanist's movie (`d28000a3…6701`) was exported with FFDec 26.3.0 (JAR `1587e60b…a841c`, the pinned one) and compared with Community Patch's Vanilla movie (`24b9c9b6…dfdf8`, the one the Community Patch adapter read):

- All 881 tags are byte for byte equal except the one `DoABC` tag, so every shape, sprite and frame (Botanist's three frames in pin sprite 588, 9.85 × 8.8, 14.7 × 13.1 and 9.85 × 8.8 px) is the same drawing.
- In the scripts exactly two lines differ: Community Patch's `HubMapPinPanel` adds `"Stables":new PinTypeDefinition("NPCs",516)` and its `MapMenu` says `frameRate="60"` where Botanist's says `"24"` (the movie headers read 60 and 24).

So Botanist's map file is Community Patch's without The Stable's row and without Smooth GUI's frame rate, as the Botanist and The Stable research of 2026-10-20 expected (section 3). What it changes over the game's map (`HubMapPinPanel.as` SHA-256 `cb5c1920…e5f1`):

| Change | Where |
|---|---|
| Category `"Botanist": new CategoryDefinition(8, true, false, false)`: priority 8, user pins shown, fast-travel pins not shown, quest pins not shown | `HubMapPinPanel._categoryDefinitions` |
| `"BotanistHGHerb"` 612, `"BotanistHG"` 613, `"Botanist"` 614, all in `"Botanist"` | `HubMapPinPanel._pinTypeDefinitions` |
| Three frames `BotanistHGHerb`, `BotanistHG`, `Botanist`; the first and last differ only by an accent colour (gold `#ffcc00` on `Botanist`, blue `#9baadd` on the other two, the colours its menu and pin texts use for "ready to harvest" and "Harvesting Ground") | pin sprite |
| Its `addPinInstance` lists only General, Quests, NPCs, Buffs and `Entrance` rows under Default, so Botanist's rows are not in Default | `HubMapPinPanel` (the game's code) |

The tab name `[[map_category_Botanist]]` resolves from Botanist's own strings (`en.csv`: `map_category_Botanist|Botanist`), which load with or without CMF.

Botanist's pins come from its scripts through Shared Utils' map pins: Botanist builds `SU_MapPin` objects with `type` and `filtered_type` both `Botanist`, `BotanistHGHerb` or `BotanistHG` (the only pin names in its `precompiled.rsblob`), and Shared Utils pushes them in its own `CR4MapMenu.UpdateUserMapPins` wrapper (`sharedutils/mappins/annotations.ws`, SHA-256 `0fc77b8a…cb9d`; `SU_updateCustomMapPins` in `main.ws` `45571f4e…387f`) when `indexToUpdate <= -1`, after the wrapped call, as `StaticMapPinData` objects with `isUserPin` and `isPlayer` false. Botanist itself wraps no map menu method.

Nothing is copied. The adapter holds only type names, the tab id, priorities, the string key, two measured sizes and two colours, which are facts about the interface, plus CMF's own placeholder art.

## How it works

| Botanist's map | Under CMF, through the adapter | CMF version |
|---|---|---|
| Botanist tab at 8 | `CMFRegister(…, 8, 'Botanist', '', "[[map_category_Botanist]]", 8)` | 2 |
| Botanist's rows not under Default | `CMFRegister(…, 23, 'Botanist', '', "", 1)` behind `CMFHasProperty(23)` (the number form of `CMFRegisterCategoryNoDefault(…, 'Botanist', true)`, so the file still compiles on CMF 5) | 6 |
| Botanist's three rows | `CMFRegister(…, 6, '<type>', '', "Botanist", 612 / 613 / 614)` | 2 |
| Botanist's three frames | `CMFRegisterIcon` and `CMFRegisterLegendIcon` with the adapter's placeholders: `herb.png` for `BotanistHGHerb` and `Botanist`, `herb_ground.png` for `BotanistHG` | 1 |
| `BotanistHG` drawn about 1.49 times the others | `CMFRegister(…, CMFPropertyPinScale(), 'BotanistHG', '', "", 149)` | 4 |
| The frames' accent colours | `CMFRegisterTint(…, 'Botanist', 16763904)`, `CMFRegisterTint(…, 'BotanistHGHerb', 10201821)`, `CMFRegisterTint(…, 'BotanistHG', 10201821)` on the white placeholders; a type tint also colours the legend row | 1 |
| No fast-travel pins in the Botanist tab | `CMFCore.OnPinReady` wrapper: every pin with `isFastTravel` gets `CMFStylePin(…, dataObject, CMFPropertyTabHide(), "Botanist", 1)` | 4 |

Everything is registered once from a `CR4Game.OnGameStarted` wrapper after `CMFRequireVersion("modBotanist", 5)`. The ground's circle is the pin's own `radius` (Botanist's "Map Pin Size" setting); CMF's pin size scales only the icon, highlight and glow (`edits.json`), so the 149 percent claim leaves the circle as Botanist draws it.

**Provider.** Every claim names `modBotanist`, Botanist's own folder (N4 spec 7.3), so Botanist keeps the same place among other mods as without CMF.

**Same values as the Community Patch adapter.** Community Patch's map carries Botanist's part unchanged, and its adapter makes the same tab, row, Default, art, size, tint and tab-hide claims with the same values (checked by `tests/test_cmf_botanist_adapter.py`). With both adapters installed, Community Patch's folder sorts first (`mod000communitypatch_worldmap` < `modbotanist`, CMF's case-blind rule) and wins every shared claim; Botanist's are logged `shadowed` and its `botanistTabHides` reads 0. That is the order without CMF too, where Community Patch's map file loads over Botanist's. The map is the same either way. If either adapter's Botanist lines change, change the other in the same round.

**Placeholder art** is the Community Patch adapter's drawing, made by the same tool (`tools/cmf_community_patch_adapter_art.py --out source/adapters/botanist/modCMFAdapterBotanist/art`), in this adapter's own texture cache (Kyle, 2026-10-20 18:05Z).

**Only Botanist's choices.** No Stables row and no `navigation` key: those are The Stable's and Smooth GUI's, in Community Patch's map, not in Botanist's. Quest and user pins need no claim: CMF tabs already leave out quest pins and show user pins, as Botanist's tab does.

**When Botanist ships its own CMF support, the player uninstalls this adapter.** Since the adapter already claims under `modBotanist`, the author's own support takes over the same claims and folder order.

**Install only with Botanist.** The adapter calls no Botanist or Shared Utils code, so it compiles without them; it cannot tell whether Botanist is installed, so it is installed and removed together with Botanist.

**Log.** CMF logs the tab and rows (`legend category id=Botanist ...`, `legend row type=Botanist... provider=modBotanist`) and, the first time it sees each, `late pin type=Botanist filteredType=Botanist`. The adapter adds one line per full map build: `CMF adapter provider=modBotanist botanistTabHides=N botanistPins=N`, the number of fast-travel pins CMF accepted a Botanist tab hide for and the number of Botanist pins CMF handed to `OnPinReady`.

## Shared Utils' pins arrive after CMF's pass (settled in game)

CMF fills pin fields in a late pass inside its own `UpdateUserMapPins` wrapper, after the wrapped call. Shared Utils pushes Botanist's pins inside its own `UpdateUserMapPins` wrapper (`scripts/local/sharedutils/mappins/annotations.ws`), after its wrapped call. Wrapper nesting by script file name was proven only for files directly in `scripts/local/`, so the archives could not say which runs last.

Launch Build 1 (2026-10-20 23:57Z) answered it: Shared Utils' wrapper runs outside CMF's. The log read `botanistPins=0` on every opening and Shared Utils' `SUMP_getManager()` came after CMF's `OnMapReady`; on screen the herbs stood as black crosses with no Botanist tab. The fix is general core work, not an adapter call: CMF now catches pins that arrive after its late pass, whatever order the wrappers nest in (PR #50, `CatchLatePins` from a `CR4MapMenu.UpdateData` wrapper, which calls `OnPinReady` for those pins and then `OnMapReady` again). It covers every mod that pushes pins through Shared Utils. Launch Build 1b (2026-10-21 00:11Z) with that fix showed the leaves, the tab and no Botanist rows under Default.

## Known differences

- **Botanist's rows under Default on CMF 5.** CMF 6's property 23 keeps them out; on CMF 5 they also list under Default.
- **Placeholder art** for Botanist's three markers until its author supplies theirs; drop-in slot `art/herb.png` and `art/herb_ground.png`.

## Files

| Path | What |
|---|---|
| `modCMFAdapterBotanist/content/scripts/local/modcmfadapterbotanist_cmf.ws` | the `OnGameStarted`, `OnPinReady` and `OnMapReady` wrappers |
| `modCMFAdapterBotanist/art/herb.png`, `herb_ground.png` | two 96 × 96 placeholders, the Community Patch adapter's drawings |
| `modCMFAdapterBotanist/README.txt` | for players |
| `tests/test_cmf_botanist_adapter.py` | static checks: the art is the Community Patch adapter's and clean, every claim matches Botanist's map file, names its folder and equals the Community Patch adapter's Botanist line, no Stables and no movement key, the tab hide covers every fast-travel pin, the log line, the pack builds |

Build: `python tools/cmf_pack.py build source/adapters/botanist/modCMFAdapterBotanist --adapts modBotanist --out <new folder>`. Ten warnings say the Botanist names are not 5.01 pin types; that is expected.

## Status

Static checks pass. Ran in game in launch Build 1b (2026-10-21 00:11Z, Kyle) on CMF with the late-pin catch (PR #50), Community Patch and its adapter out: gold and blue placeholder leaves on the herbs, the Botanist tab with its rows, no Botanist rows under Default. Pack: a launch record kept in the private development repository. Without PR #50 the claims all win but Botanist's markers show as black crosses (launch Build 1).

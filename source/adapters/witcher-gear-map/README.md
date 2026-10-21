# Witcher Gear Map adapter (proof of concept)

`modCMFAdapterWitcherGearMap` is a separate mod that sits between Conjunction Map Framework (CMF) and Witcher Upgrade Gear Map 1.0.1 (Nexus 14157). It lets Gear Map's markers draw on CMF's world map under Gear Map's own pin type names, with Gear Map unchanged. It is CMF's first adapter. It follows Kyle's principle of 2026-10-19: carry over the names another mod already uses, bridge the rest with a separate adapter mod. Since 1.0.1 it ships the gear art of Gear Map's author, MateusAnd, with their permission (2026-10-21; Kyle's rule of 15:12Z: an author's art ships in the adapter only with their explicit permission). The author-facing version is [`docs/authors/witcher-gear-map-adapter.md`](../../../docs/authors/witcher-gear-map-adapter.md).

## Provenance

Traced from the reference archive `WitcherGearMap 14157 1.0.1 2026-10-12T11-20Z FLZ3sa9zo.zip` (SHA-256 `44fcaa56ebfa731a4a453a815556266b737b4019f52ae8f6a510e9051746b334`, the hash in the compatibility write-up), read only, on 2026-10-19:

- `mods/modWitcherGearMap/content/scripts/local/wgm.ws`, the `@wrapMethod(CR4MapMenu) UpdateEntityPins` wrapper. After `wrappedMethod`, it creates one `red.game.witcher3.data.StaticMapPinData` per visible location with `CreateTempFlashObject` and pushes it into the array. It never calls `AddPinTypeData`. Fields: `type` is built as below, `filteredType` is always `"WitcherGear"`, `label` is the marker title, `description` is the diagram list and hint, `isQuest`, `isPlayer`, `isUserPin` and `isFastTravel` are false, `radius` is 0. No `tag` is set.
- `type` is `"WitcherGear"`, plus `"Obtained"` when every shown diagram there is learned, plus the school from `wgm_IconSuffix` (`Cat`, `Griffin`, `Bear`, `Wolf`, `Viper`, `Manticore`) when the `wgm_IconStyle` option is 1 or 2, plus `"Ring"` when the option is 1. That gives 26 names: 2 for style 0, 12 for style 1 and 12 for style 2.
- `README.md` and `LICENSE`: CC BY-NC-SA 4.0. Gear Map's own map file adds 26 frames under those names and a "Witcher Gear" legend category (compatibility write-up, section 2).

Nothing is copied. The adapter holds only the type names, which are facts about the interface, and the author's gear art, given for the adapter (never stored in CMF itself).

## How it works

| Step | Who | Evidence |
|---|---|---|
| Register one picture for each of the 26 names from an `OnGameStarted` wrapper | adapter, CMF 1 named calls | the same plug-in pattern as every CMF pack |
| Gear Map pushes its markers in `UpdateEntityPins` | Gear Map, unchanged | `wgm.ws` |
| Vanilla `UpdateData` calls `UpdateUserMapPins` after `UpdateEntityPins` on the same array | vanilla | pin sources inventory, section 2 (`mapMenu.ws:337-344`) |
| CMF's late pass (`UpdateUserMapPins` wrapper, `FillMissingPinFields`) writes `cmf*` fields onto pins without `cmfDone` | CMF core | `cmfCore.ws` |
| The panel draws `cmfIconPath` over the pin and carries `cmfLegendIconPath` to the legend row | CMF panel | `source/panel/pin-fields/edits.json` |

**No wrapper-order dependency.** The adapter wraps only `CR4Game.OnGameStarted`, and CMF's late pass runs after every `UpdateEntityPins` wrapper whatever the script file names. So the file is named by the pack convention (`modcmfadapterwitchergearmap_cmf.ws`), not to sort after `wgm.ws`. Version 0.2 keeps that name: its new calls are registrations too, so the order is still irrelevant. A rename would also leave the old file behind on an install that cannot delete it.

**Install and remove it together with Gear Map.** `modcmfadapterwitchergearmap_cmf.ws` references none of Gear Map's functions, but `modcmfadapterwitchergearmap_stable.ws` calls them, so the scripts fail to compile without Gear Map (Kyle's rule of 2026-10-21 02:25Z: an adapter gives nothing of its mod unless the mod is installed).

**When another mod replaces `UpdateEntityPins`.** The Stable 2.2.1 ships a precompiled `CR4MapMenu.UpdateEntityPins`, and while it is installed Gear Map's wrapper on that method never runs: no Gear marker reached the map in final matrix launch M1, and they came back in M1c with The Stable out (2026-10-21). `modcmfadapterwitchergearmap_stable.ws` wraps `UpdateUserMapPins`, which vanilla `UpdateData` calls right after `UpdateEntityPins` on the same list and which The Stable leaves alone. Before the user pins it looks for a pin with `filteredType` `WitcherGear`; only when there is none does it build the markers by calling Gear Map: `theGame.wgm_GetData()` (its locations and diagrams), `wgm_ConfigBool` and `wgm_ConfigInt` for its options, `wgm_WorldKey`, `wgm_Discovered`, `wgm_SchematicName`, `wgm_MarkerTitle`, `wgm_DiagramName`, `wgm_IconSuffix` and `wgm_Loc`, the diagrams the player knows, and its id offset. It holds no location, diagram or text of its own, and when Gear Map's own wrapper runs it adds nothing. It names no other mod. Not yet launched.

**Provider.** Every claim names `modWitcherGearMap`, Gear Map's own folder (N4 spec 7.3, since N4; it was `modCMFAdapterWitcherGearMap` before), so folder order between mods is the same with CMF as without it. The art stays in the adapter's own cache under `img://icons/modcmfadapterwitchergearmap/`. Gear Map gives its pins numeric ids (`1464287232 + n`), so other mods reach them by type or per pin, not by a tag name.

**Legend under CMF 2 (version 0.2, static checks only).** CMF 2 adds legend rows and filter tabs as data (version 2 spec, section 4). The adapter registers Gear Map's own names, guarded by `CMFHasProperty(8)` so the file still compiles on CMF 1:

| Call | Property | Target | Value | Gear Map's own source |
|---|---|---|---|---|
| `CMFRegister(…, 8, 'wgm_gear', '', "[[map_category_wgm_gear]]", 8)` | legend category | tab id `wgm_gear` | name, tab order 8 | its panel's category `"wgm_gear": (8, …)`; string `map_category_wgm_gear` = "Witcher Gear" (id 2117400003) |
| `CMFRegister(…, 6, 'WitcherGear', '', "wgm_gear", 703)` | legend row | `filteredType` `WitcherGear` | in tab `wgm_gear`, priority 703 | its panel's row `"WitcherGear": ("wgm_gear", 703)` |
| `CMFRegister(…, 7, 'WitcherGear', '', "[[wgm_label]]", 0)` | legend label | `filteredType` `WitcherGear` | row name | its panel's label swap to `[[wgm_label]]` = "Witcher Gear" (id 2117400011) |

The string keys resolve from Gear Map's own `w3strings` (hash-matched in `research/2026-10-19-settings-and-localization.md`), so the adapter ships no Gear text. The adapter also registers the row's image on the legend key itself, `CMFRegisterLegendIcon(…, 'WitcherGear', gear.png)`, so the row keeps its art if the core's legend fallback to a marker type's own art ever changes. The three property ids sit in one block of the script. If CMF changes them, that block is the only edit.

**Legend under CMF 1.** CMF 1's map has no "Witcher Gear" category. The vanilla `HubMapPinPanel.addPinInstance` still adds a row under All for an unknown `filteredType`, labelled with the first pin's `label`, and CMF's patch carries the legend art there. Seen in game on 2026-10-20 at 00:26Z: one row under All, labelled "Wolf School · Enhanced Armor (Legendary)" 1/36, took the test pack's tint on the `filteredType` `WitcherGear`. Gear Map's own tooltip text showed unchanged.

## What it needs from the core

The per-property key fallback in the core's late pass (`55ef6e1`, merged into foundation with PR #10). Pin art, tint and appearance are looked up by the pin's `type` first and then its `filteredType`. The legend row's art and tint are looked up by `filteredType` first and then `type`. So each of the 26 types gets its own art and tint, and the `WitcherGear` claim also names the legend row. Before that change, every Gear marker took the `WitcherGear` claim whatever its state or school. The core also logs `CMF late pin type=... filteredType=...` for pins other mods push, which shows whether Gear's pins reached the late pass.

The observation run (CMF plus unchanged Gear Map, 2026-10-20 00:23Z, `probes/2026-10-20-cmf-gear-diag`) showed 36 Gear markers reaching the late pass as `WitcherGearObtained` with `filteredType` `WitcherGear`. A test tint on the own type was applied, and the markers drew as the black X CMF's movie shows for a type with no frame. So `gotoAndStop` on a missing frame does not stop the renderer, and no panel change is needed for the adapter.

**A Gear Map issue, independent of CMF.** On a fresh install Gear Map's School, Tier and Icon style options have no stored value until the player changes them once. Until then its script reads them as `"-1"`, and the school filter drops every marker (seen in the same run). Moving each option away and back stores `0`.

## Files

| Path | What |
|---|---|
| `modCMFAdapterWitcherGearMap/content/scripts/local/modcmfadapterwitchergearmap_cmf.ws` | 26 `CMFRegisterIcon` calls and one `CMFRegisterLegendIcon` call, plus the CMF 2 block of three `CMFRegister` calls. No tints: the author's art is coloured per school already |
| `modCMFAdapterWitcherGearMap/art/gear*.png` | MateusAnd's 26 pictures, 96 x 96, one per type, from `CMF_adapter_art_GwentPlayersMap_WitcherGearMap.zip` (SHA-256 `3b287729e1ccc77dc595484767b57ca5de4852693be0e545e9feb5b3dfb5ed0f`), unchanged. The zip's `gear_ring.png` and `gear_obtained_ring.png` (no colour, with a circle) match no type Gear Map sends, so they are not shipped. `gear_obtained_griffin.png` and `gear_obtained_manticore.png` lose a little colour where grey meets the school colour when compressed (8% and 13% of visible pixels); seen side by side and accepted |
| `modCMFAdapterWitcherGearMap/README.txt` | For players |
| `tests/test_cmf_gear_adapter.py` | Static checks: one author picture per type and no tint, the 26 names match Gear's rule, every claim names `modWitcherGearMap`, the script stands alone, the pack builds |

Build: `python tools/cmf_pack.py build source/adapters/witcher-gear-map/modCMFAdapterWitcherGearMap --adapts modWitcherGearMap --out <new folder>`. The tool reports 51 warnings, one per claim, saying the Gear names are not 5.01 pin types. That is expected.

Up to 1.0.0 the adapter drew four placeholders of its own and coloured them with one tint per school. Since 1.0.1 every school type has the author's own coloured picture and no tint, so nothing is coloured twice.

## In-game result

**PASS, 2026-10-20 00:32Z** (Kyle; the main thread read the log at 00:33Z; record a launch record kept in the private development repository). Setup: Windows 5.01 probe copy, core equal to foundation `46ac175`, CMF's two test packs, unchanged Gear Map 1.0.1 and this adapter, on Kyle's NG+ save with every diagram learned.

- The log has `CMF provider=modCMFAdapterWitcherGearMap claims=50 won=50 shadowed=0` (the provider name before N4; since N4 it reads `modWitcherGearMap`), with no `art failed` line and no script errors.
- The markers showed the adapter's art in place of the black X, in all three icon styles, with the plain, school-coloured and ringed types. Gear Map's tooltip was unchanged.
- **Selected-pin art was seen for the first time:** an enlarged, selected marker keeps its custom art.
- The legend has one row under All. It shows the plain sheet in every style; see the limits below. In this run the row was red, because the core's legend tint fell back to the first marker's own type, a Wolf school tint. The main thread fixed this in `a1311cf`, which takes the legend tint from `filteredType` only and leaves the row neutral unless the adapter registers a legend tint of its own. That fix is not yet tested in game.

## Limits

- The legend row shows the plain sheet whatever Gear Map's icon style is, because every marker shares the `WitcherGear` legend key (Kyle, 2026-10-20 00:32Z: the ring does not appear on the legend). This is by design. A per-style legend icon would need the adapter to read Gear Map's `wgm_IconStyle` setting in an `OnConfigUI` wrapper; it was left out to keep the proof of concept free of Gear Map's settings names.

- Under CMF 1: no "Witcher Gear" category or translated row name, and no count in a category of its own. CMF 2 adds them (above); not yet seen in game.
- Tested on Windows only; Proton not checked.

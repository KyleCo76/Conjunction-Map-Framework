# All Quest Objectives adapter

`modCMFAdapterAllQuestObjectives` is a separate mod that sits between Conjunction Map Framework (CMF) and All Quest Objectives On Map - Remastered 1.2.1 (Nexus 14319, folder `modAQOOMRemastered`). It brings back three of that mod's map features:

- **Difficulty icons**: the coloured badge on objectives of quests the player does not follow. It uses CMF's per-pin icon and tint calls (API version 2) from the pin hook `CMFCore.OnPinReady` (API version 4), with two placeholder pictures of the adapter's own.
- **Its own legend row** "All Quest Objectives" for objectives of quests the player does not follow, in the Quests tab at the mod's priority 200. It uses `CMFRegisterLegendRow` and `CMFRegisterLegendLabel` (API version 2) under CMF's quest-row rule (API version 6): a won row claim on a quest pin's `filteredType` takes those quest pins out of the shared quest row (author guide, "Quest rows").
- **Removing a cached merchant pin** by using it twice. It uses CMF's pin clicks (API version 6, property 16 `PinClick` and the hook `CMFCore.OnPinClicked`), as designed in the pin click research (a launch record kept in the private development repository, sections 3.2 and 5.1) and taught in the author guide (`docs/authors/icon-pack-guide.md`, "Pin clicks").

It also gives the mod its name in CMF's in-game menu: `CMFSetProviderName("modAQOOMRemastered", "All Quest Objectives")` (API version 8, adapter 1.1.0), called once per game start beside the row. Without it the menu tidies the provider's folder name to "AQOOMRemastered" (seen in the CMF 1.2.1 release test). The name is the mod's own text for its row (`FILTER_LABEL`) and changes nothing on the map.

All Quest Objectives is unchanged. The adapter adds no rule of its own. The page for the mod's authors is [`docs/authors/all-quest-objectives-adapter.md`](../../../docs/authors/all-quest-objectives-adapter.md).

## Teaching example

"Your map file used to draw `gotoAndStop(wmkIcon)` and send `OnStaticMapPinUsed(id, -(aqoomCachedPin + 999))`. Now you style each marked pin and claim the click on each cached pin, and CMF draws the icon and calls you back."

| Before (All Quest Objectives' own map file) | Under CMF (this adapter) |
|---|---|
| The script writes `wmkIcon` (a frame name) on each `QuestObjectiveOther` pin with a known level. `StaticMapPinDescribed` draws `gotoAndStop(wmkIcon ? wmkIcon : type)`, and the 19 frames `WmkQuestIcon*` and `WmkExclamationIcon*` are drawings inside its map file | An `OnPinReady` wrapper reads `wmkIcon` and calls `CMFStylePinIcon(provider, pin, "img://icons/modcmfadapterallquestobjectives/badge.png")` (or `mark.png` for the exclamation names), then `CMFStylePinTint(provider, pin, colour)` with that frame's colour. The pictures are white, so the tint gives them the mod's colour and the dark parts stay dark |
| `StaticMapPinData` declares `aqoomCachedPin:int`; the script sets it to the merchant's list index + 1 on each cached pin it pushes | Unchanged. CMF's map declares the same field (and `wmkIcon`) for this adapter, so the values survive |
| `HubMap.UseSelectedPin` gains `else if (aqoomCachedPin > 0)` sending `OnStaticMapPinUsed [id, -(aqoomCachedPin + 999)]`, so E, Enter, gamepad A, a double-click and a tap act. `CanSelectedPinBeUsed` is unchanged, so there is no hold ring | The same `OnPinReady` wrapper calls `CMFStylePin("modAQOOMRemastered", dataObject, CMFPropertyPinClick(), "use, doubleClick", aqoomCachedPin)` on each pin with `aqoomCachedPin > 0`. `use` is E, Enter, gamepad A and a tap, and `doubleClick` the mouse double-click. Claimed pins get no hold ring |
| `addPinInstance` puts quest pins whose `filteredType` is `QuestObjectiveOther` into their own row, keyed `QuestObjectiveOther`, in the game's Quests category, at priority 200, labelled with `aqoomRowLabel` (always the constant `FILTER_LABEL` "All Quest Objectives"); `HubMap`'s show and hide follow that key | An `OnGameStarted` wrapper calls `CMFRegisterLegendRow("modAQOOMRemastered", 'QuestObjectiveOther', 'Quests', 200)` and `CMFRegisterLegendLabel("modAQOOMRemastered", 'QuestObjectiveOther', "All Quest Objectives")`. CMF's map then lists, counts, shows and hides those quest pins in that row |
| An `OnStaticMapPinUsed` wrapper (`aqoomMapHooks.ws` 40-50) calls `AqoomGetMap().IsCachedPinUse(pinTag, areaNameId)` and, when true, `OnCachedPinUsed(this, areaNameId)` | An `OnPinClicked` wrapper rebuilds `areaNameId = -(value + 999)` from the claim's value and makes the same two calls with the map menu CMF passes. Every other provider's click goes on through `wrappedMethod` |

The mod's own `OnStaticMapPinUsed` wrapper stays installed and idle, because CMF never sends a negative area number. Its messages, sound, removal and map rebuild run in its own `OnCachedPinUsed`, as before.

### The icons

| Name (the mod's own) | Picture | Colour |
|---|---|---|
| `WmkQuestIconWhite`, `Gray`, `Green`, `Yellow`, `Orange`, `Red` | `badge.png`: a white disc with a dark rim and a dark exclamation mark | `FFFFFF`, `999999`, `89D889`, `FFCC00`, `FF9900`, `D95050` |
| `WmkExclamationIcon` + `White`, `LightGray`, `Gray`, `Green`, `PureGreen`, `AltGreen`, `Yellow`, `Orange`, `LightRed`, `Red`, `DarkRed`, `Magenta`, `Pink` | `mark.png`: a white exclamation mark with a dark outline | `FFFFFF`, `CCCCCC`, `999999`, `89D889`, `00FF00`, `06B952`, `FFCC00`, `FF9900`, `FF6666`, `FF0000`, `A60000`, `FF00FF`, `FF99FF` |

By default the mod uses `WmkQuestIconGray` (low), `Green` (normal), `Orange` (high) and `Red` (deadly), by the game's own suggested-level rule (`aqoomMap.ws` 55-58 and 345-375). Quests without a level get no name and keep the game's icon. The other 15 names appear only when a player edits the mod's script constants. An unknown name keeps the game's icon and logs `result=unknown`.

The pictures are our own drawings (`adapter_art.py`, deterministic, 96 x 96, 4 px clear edge), in the adapter's own `texture.cache` (Kyle, 2026-10-20 18:05Z and 18:14Z: placeholder art lives in the adapter and reaches CMF as the mod's author would send it). The colours were read from the mod's frames. CMF fits each picture into the box of the game's `QuestObjectiveOther` glyph (15 px), so the badge comes out about the size of the mod's 13.7 px badge.

## Claim order

- **Level.** Every claim is made on one pin (`CMFStylePinIcon`, `CMFStylePinTint` and `CMFStylePin` inside `OnPinReady`), the most specific level. It beats any tag claim (`CMFRegisterForTag`) or type claim (`CMFRegister`) another mod makes for the same pin, such as a pack's type-level tint on `QuestObjectiveOther`.
- **Same level.** Against another one-pin style or claim on the same pin, the earlier folder in CMF's provider order wins (folder order, ignoring case, unless the player set `CMFProviderOrder` lines), then the earlier call. `modAQOOMRemastered` sorts before `modMapQuestInsight`, so with both adapters installed this one's icon and tint win on untracked objectives. Map Quest Insight's own author calls the two mods incompatible. A losing click claim is logged once (`CMF click shadowed provider=... by=...`) and never hears the click.
- **Which pins.** Icons go only on pins carrying `wmkIcon` (untracked quest objectives, written by the mod). Clicks go only on pins All Quest Objectives pushed as cached merchants (`aqoomCachedPin > 0`), which carry `isFastTravel` and `isQuest` false, so CMF lets the claim take `use` and `doubleClick`. Signposts, tracked quests, live merchant pins and the player's own pins are never touched, so the Map Pin Teleport adapter (user pins) and this one never meet.
- **Hint and button.** None: All Quest Objectives shows neither, so ids 20 and 21 are not claimed.

## Provenance

Read directly on 2026-10-20 from Kyle's reference archive `All Quest Objectives On Map - Remastered 14319 1.2.1 2026-10-18T10-52Z oDUKYHoAV.zip` (SHA-256 `850311922fe812548e9c04e168e40906c0e6cb388e91c11438b9061a15bb95fc`, 1 585 795 bytes, `source\compatability-candidates`, staged read-only through this thread's folder card). It holds four files and nothing under `bin\`:

| File | SHA-256 |
|---|---|
| `aqoomMap.ws` (746 lines) | `dbddec7d1ec5cb33053ba86d8e81f68cfb1efbb14f624193c9e83d67dde92a6d` |
| `aqoomMapHooks.ws` (63 lines) | `81981e5a566db71915992381145484ee98003193dcdeeb061585d08dc05261b6` |
| `blob0.bundle` (its map file; movie `a8c87a046ca19535669e614a6e14ce55486bc7d2a39c66a806307163b4b89a5f`) | `e4a4ec5c7a4bda749796e9fa21b68aacdad6e67f073e19123b5789da5fafbc7e` |

Read for its interface only. Nothing is copied: the frame colours were read from its shapes (`PinIcon` sprite 588, frames 1473-1491, shapes 1000-1012 and 1020-1025), and the pictures were drawn anew.

| Name | Where | Used for |
|---|---|---|
| `AqoomGetMap() : AqoomMap` | `aqoomMap.ws` 732, global | the mod's map object |
| `public function IsCachedPinUse(pinTag : name, areaNameId : int) : bool` | `aqoomMap.ws` 226 | the mod's own test: the index `-1000 - areaNameId` is in range and that merchant's tag is `pinTag` |
| `public function OnCachedPinUsed(mapMenu : CR4MapMenu, areaNameId : int)` | `aqoomMap.ws` 238 | first use shows "Select again the same cached pin to remove it."; the second removes the pin, plays `gui_hubmap_remove_pin` and rebuilds the map |
| `aqoomCachedPin` (pin field) | `aqoomMap.ws` 636 | the merchant's list index + 1 |
| `wmkIcon` (pin field) | `aqoomMap.ws` 307 | the icon name of an untracked objective (`type == "QuestObjectiveOther"`, known level) |

`pinTag`: CMF's map passes the pin's flash id into a `name` parameter, exactly as the game's own `OnStaticMapPinUsed` does. All Quest Objectives gives each cached pin `id = NameToFlashUInt(pin.tag)`, so the tag reaches `IsCachedPinUse` as it did under the mod's own map file (research section 6: *inferred*; the launch step below proves it).

## Log

- First eight difficulty icons of a session: `CMF adapter provider=modAQOOMRemastered icon=<name> type=QuestObjectiveOther result=styled|refused|unknown`.
- First eight cached pins of a session: `CMF adapter provider=modAQOOMRemastered cached=<n> type=<pin type> result=claimed|refused`.
- Each click: CMF's own `CMF click provider=modAQOOMRemastered input=use type=... pin=... tag=... value=<n>`, then `CMF adapter provider=modAQOOMRemastered click input=use value=<n> tag=<tag> result=used|notcached`. `notcached` means All Quest Objectives' own test refused it (for example a stale index), as its own wrapper would have.

## Dependencies

- **All Quest Objectives 1.2.1, a compile dependency.** The adapter calls its functions. It is installed and removed together with that mod, and removed first.
- **CMF API version 8** (CMF 1.2.0) to compile, from adapter 1.1.0: `CMFSetProviderName`. The click claim and hook need version 6 (`CMFPropertyPinClick`, the `OnPinClicked` hook). Earlier CMF versions stop at the compile screen; players on them keep adapter 1.0.0.
- **Saves.** The adapter writes nothing into saves. All Quest Objectives keeps its merchant list in saves made while it is installed, so probe launches end without saving.

## Files

| Path | What |
|---|---|
| `modCMFAdapterAllQuestObjectives/content/scripts/local/modcmfadapterallquestobjectives_cmf.ws` | the icon table, the `OnPinReady` icon styling and click claim, and the `OnPinClicked` answer |
| `modCMFAdapterAllQuestObjectives/art/badge.png`, `mark.png` | the two placeholder pictures, cooked into the pack's `content/texture.cache` by `tools/cmf_pack.py build` |
| `modCMFAdapterAllQuestObjectives/README.txt` | for players |
| `adapter_art.py` | draws the two pictures (developer only; kept beside the adapter) |
| `tests/test_cmf_aqo_adapter.py` | static checks: the two hook wrappers keep CMF's signatures and pass other providers on; the icon table matches the mod's 19 names and colours and the pictures are 96 x 96; the click claim is per pin with the mod's folder as provider and `use, doubleClick` only; the fake area number matches the mod's map file; only the three All Quest Objectives names are called; no pin field is written; WitcherScript hygiene; the menu name is set once, beside the row, with the mod's folder as provider; the pack tool in adapter mode. With `CMF_AQO_SCRIPTS` set to the mod's `content/scripts/local`, the signatures and the name list are checked against its files too (passed 2026-10-20); otherwise that case is skipped, which is not qualification |

Build: `python tools/cmf_pack.py build modCMFAdapterAllQuestObjectives --adapts modAQOOMRemastered --out <folder>`. The check gives no warnings: the tool counts the image paths passed to `CMFStylePinIcon` as uses of `art/badge.png` and `art/mark.png`.

## Status

Launch P6+C2 run 2 (2026-10-20 ~20:05Z, record a launch record kept in the private development repository, revision 3 at `9b817cb`, a launch record kept in the private development repository) passed on Windows with keyboard and mouse:

- The adapter compiles with CMF API version 6 and All Quest Objectives 1.2.1.
- Difficulty icons: proven. Green badges showed on untracked objectives, and the tracked quest kept the game's gold marker.
- Legend row: proven. The "All Quest Objectives" row showed in the Quests tab; hiding it removed those objectives and kept the tracked gold marker.
- Cached merchant pin click: not tried in game. It needs a merchant the game has stopped showing, and the step was optional.

Adapter 1.1.0 (the menu name) passed on 2026-10-22 in two launches, the second from its release archive in the CMF 1.2.2 release test: the menu's Legend row read "Automatic (All Quest Objectives)", with no rejection or compile error.

## Limits

- **The legend row needs CMF's quest-row rule** (API version 6 builds from `bbf71de`; on an earlier version 6 build the row does not appear). All Quest Objectives lists untracked objectives in their own row ("All Quest Objectives", its constant `FILTER_LABEL`, written as `aqoomRowLabel` on every `QuestObjectiveOther` pin, `aqoomMap.ws` 291). Before the rule, CMF's map put every quest pin into the one shared quest row before any row claim was looked at. The label is passed as the same constant text; if the author ever changes `FILTER_LABEL`, the adapter follows by hand.
- The badge and mark are placeholders in the mod's colours, not the mod's own drawings, until its author ships CMF support.
- Gamepad A and touch taps are not checked (no controller or touch screen).
- Windows only; Proton not checked.

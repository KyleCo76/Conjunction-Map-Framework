# Ink and Iron adapter

`modCMFAdapterInkAndIron` is a separate mod that sits between Conjunction Map Framework (CMF) and Ink and Iron (0.8.7 to 0.9.0 read; the separate `modInkAndIronUI` folder or the All In One file's `modInkAndIron` folder, proven with 0.8.9 on 2026-10-21). With CMF installed, CMF's world map replaces Ink and Iron's map, while Ink and Iron's HUD, compass and menus load as normal. This adapter brings back what Ink and Iron's map adds, through CMF's general calls:
- its look (CMF 5's `CMFStylePart`, `CMFDraw` and `CMFDrawSet`);
- its quest-level tags (`OnPinReady`, `CMFStylePinLabel`, property 17 `LabelColor`);
- its key-hint row (`cmf.map.hints`);
- its map movement: panning and zoom stepped by the time since the last drawn frame, and its 60 frames a second (CMF 6's `navigation` keys);
- its gold controller button pictures (All In One), all 143 buttons of the five controller families, through CMF 9's `CMFRegisterButtonPicture`;
- the world overview of its optional World Map file (0.9.0): the engraved painting and the seven region crests, as pictures in the adapter's own `texture.cache` (CMF 9's `CMFRegisterWorldPainting` and `CMFRegisterWorldCrest`), choice-only (`CMFRegisterChoiceOnly`), and its name "Ink and Iron" in CMF's in-game menu (CMF 8's `CMFSetProviderName`).

It is written as the code Ink and Iron's author would add upstream. [`docs/authors/ink-and-iron-adapter.md`](../../../docs/authors/ink-and-iron-adapter.md) is that guide. The design is a design note kept in the private development repository section 5. Every value, with the movie member it was read from, is in a launch record kept in the private development repository.

## Provenance

These parts of Ink and Iron were read only, for its interface and its look's values:
- `inkironui_map.ws`, lines 1-107: the hint row;
- `inkironui_questlevel.ws`, lines 104-105;
- its 0.8.7 map file `panel_worldmap.redswf`, decompiled with the pinned FFDec: `MapMenu.ink*`, `iiFrame`, `HubMapContainer.inkEdge`/`inkLim`, `TooltipMap.inkFont`, `InputFeedbackButton.inkSyncCap`, `KeyboardButtonIcon.label`, `HubMapPinCategoryItemRenderer`, `StaticMapPinDescribed.iaiLvTab`, and the `HubMap`/`UniverseMap` navigation;
- its 0.8.10 map file, compared with 0.8.9 by the review a launch record kept in the private development repository: the info box framed on every view (`inkPinTipPanel`), a second fill under a box 330 px or taller with its padding, and `inkTipPlace`, which moves such a box clear of the cursor and the panels. Adapter 1.1.0 restores these with CMF 7's `minPartHeight` (drawing `inkTipBacking`) and the `tooltip` clear keys, both asked for with `CMFHasAbility` first; the values are inferred from the review, not from Ink and Iron's code;
- its 0.8.8 map file (the same `panel_worldmap.redswf`), read for the movement by the smooth map movement research (a launch record kept in the private development repository, sections 4.1 and 6.1): `HubMap` `Timer(1)` and `handleScrollAndZoomTimer` (pan scaled by elapsed / 17 ms, cap 100 ms; zoom once per 17 ms through an accumulator), `UniverseMap` (elapsed / 24 ms), and the movie's frame rate 60.

The adapter copies no code. The look is numbers (colours, sizes, positions, fonts) handed to CMF's own drawing, and the hint gathering repeats the three calls of Ink and Iron's `InkMapHints` with Ink and Iron's own `InkGatherHints`.

**Art, with the author's permission.** WinterElfeas, Ink and Iron's author, answered Kyle on 2026-10-23, when asked to let CMF carry the World Map art at least while they look at building CMF support themselves: "You can go ahead to carry it in the CMF pack" (record under a launch record kept in the private development repository). `modCMFAdapterInkAndIron/art/world/` holds that art, cut unchanged by `tools/cmf_ink_and_iron_art.py world` from the World Map 0.9.0 download (`Ink and Iron - World Map 13111 0.9.0`, zip sha256 `4854ee542ce438483a9cc422b80537a5ac4827eac440e1f9c6b704f2db55c5f3`):

| Picture | From the World Map file's `panel_worldmap.redswf` | Size |
|---|---|---|
| `painting.png` | texture `_i313` (DXT1), the whole overview painting | 2100 x 1380 |
| `crest_kaer_morhen.png` | `_i1` cut-out 759 (x 743-878, y 328-458), the wolf medallion | 135 x 130, saved 136 x 132 |
| `crest_skellige.png`, `crest_novigrad.png`, `crest_no_mans_land.png`, `crest_wyzima_castle.png` | `_i1` cut-outs 769, 749, 739, 729 (y 770-886) | 135 x 116, saved 136 x 116 |
| `crest_bob.png`, `crest_prolog_village.png` | `_i1` cut-outs 782, 777 (y 646-762) | 135 x 116, saved 136 x 116 |

BC3 needs sides in multiples of 4, so each crest is resized one step up; the map stretches it back to the game's own rectangle. The All In One 0.9.0 keeps the game's painting and crests (byte for byte the same as CMF's own map file), so only the World Map file's pictures differ.

| Ink and Iron name | File | Used for |
|---|---|---|
| pin fields `iaiLv`, `iaiDiff` | `inkironui_questlevel.ws` 104-105 | the quest level and its difficulty, written only while its option "Quest levels on world map pins" is on |
| `InkGatherHints(st, arr, bindersList, level, isContextBinding)` (method on `CR4CommonMenu`) | `inkironui_map.ws` 65 | gathers the common menu's bindings into a flash array |

## How it works

| Piece | Where | What |
|---|---|---|
| Quest levels | `@wrapMethod(CMFCore) OnPinReady` | on a quest pin with `iaiLv` above 0: the label "Lv " and the level (Ink and Iron's text in every language) with `CMFStylePinLabel`, and its difficulty colour (#8A8578, #EFE6CF, #E0893A, #D0402F) with `CMFStylePin(..., CMFPropertyLabelColor(), ...)` |
| Hint list | `@addMethod(CR4CommonMenu) InkAdapterMapHints` | builds the list as Ink and Iron does and sends it to `"cmf.map.hints"` in the map menu's flash storage |
| Every rebuild | `@wrapMethod(CR4CommonMenu) UpdateInputFeedback` | after Ink and Iron's own wrapper, sends the list again |
| Map ready | `@addMethod(CR4MapMenu) event OnCMFMapHintsReady` | CMF's map calls it once its hint listener is registered; the adapter sends the current list |
| The look | `@wrapMethod(CR4Game) OnGameStarted` | after `CMFRequireVersion("modInkAndIronUI", 5)`, about 270 calls in all: map area and edge fade, screen fades, the three frames, text, title, legend, overview, key caps, level-tag plate, custom-marker panel, navigation |
| World overview | `InkAdapterWorldOverview`, in the same wrapper | `Painting_World` and `Painting_Crests` made choice-only for `modInkAndIronUI`, then the painting and the seven crests; `CMFSetProviderName("modInkAndIronUI", "Ink and Iron")` just before |
| The movement | `InkAdapterLookNavigation`, in the same wrapper | CMF 5's `frameTimed` 1, `stepMs` 17, `worldStepMs` 24, `maxStepMs` 100 and the controller crosshair keys; from CMF 6, each behind `CMFHasAbility('navigation', key)`, `zoomTimed` 0, `padHoldMs` 0 and `frameRate` 60 |

**World overview, choice-only.** The World Map file is optional and has no script, so nothing tells the adapter whether it is installed. The overview pictures therefore never show under Automatic: only when the player picks Ink and Iron on the menu add-on's **World overview** and **Region crests and markers** rows (or the Basic **Painting** row), or writes `CMFFile_Painting_World=modInkAndIronUI` and `CMFFile_Painting_Crests=modInkAndIronUI` under `[CMFSettings]`. A player without the World Map file sees the game's overview, as Ink and Iron's own map shows it. Revision 9 spec: a launch record kept in the private development repository section 13.

**Gold controller buttons, on by default.** Ink and Iron's map file (All In One, every version read) re-draws the controller button sheets `_i49` and the lower rows of `_i1` with gold outlines and keeps the game's layout. `modCMFAdapterInkAndIron/art/buttons/` holds all 143 pictures (five controller families), cut by `tools/cmf_ink_and_iron_art.py buttons` from the All In One 0.9.0 download (zip sha256 `a97db50f3f72e2f5f57bd3b26f78e5a63a18c5c2dc3672dc065dde8035a5d1f6`) at the game's places (`tools/cmf_button_sheets.json`); every one differs from CMF's own map file. `modcmfadapterinkandiron_buttons.ws` registers them under `modInkAndIronUI` in its own `OnGameStarted` wrapper. They ship in the All In One every player of this adapter has, so they are not choice-only and answer the Map look (Look_Hints) choice. Kyle confirmed on 2026-10-23 that the author's permission covers them too.

CMF's own hint row already sits at Ink and Iron's place, size and glow (A1), so the adapter makes no `hints` call.

**Movement.** Ink and Iron's map pans by the time since the last drawn frame (17 ms steps on the region map, 24 on the world view, gaps over 100 ms capped), keeps its key and stick zoom at one step per 17 ms, uses each stick reading once as the game does, and runs its movie at 60 frames a second, so its tweens and looping animations update 60 times a second. `zoomTimed` 0 and `padHoldMs` 0 equal the game's values but are sent anyway: they are Ink and Iron's own choices, and a later folder's smooth-map keys must not replace them (theme spec 4.5, "Behaviour keys"). Ink and Iron opens and closes its map as the game does, leaves the game's tweens and zoom-out limit, and draws no button beside a pin, so the adapter sets no `opening` key, no `tweenEveryFrame`, `zoomOutFit` or `edgeOvershoot`, and no `pinButton` style. Ink and Iron has no switch for its movement, so nothing is ever `unset`. On CMF 5, `CMFHasAbility` answers false for the three new keys and the adapter loads with the rest.

Every claim names `modInkAndIronUI`, Ink and Iron's own folder, as its provider (N4 spec 7.3). Ink and Iron's styles therefore win over any pack that sorts after it, and give way only to one that sorts before it.

**Frames.** Each frame's shadow is one ring repeated 28 times, 1 px further out each time, with its 28 opacities listed (`repeat`, `repeatStep`, `alphaList`). 5.01 script cannot turn a string into a name, so drawing ids cannot be made in a loop.

**Glitches not copied** (Kyle, 2026-10-20: "Don't copy a broken function"):
- **Region title.** Ink and Iron's title field keeps the game's line wrap, so a long name is cut at a word ("VELEN - NO") and its diamond sits low. Here the title stays on one line (`wrap` `none`) with the diamond centred on it. `wrap` `keep` brings the cut back.
- **Legend frame.** It always wraps every row shown.

**Pin fields.** CMF's panel declares `iaiLv` and `iaiDiff` as compatibility names for this adapter, because the game drops pin fields its class does not declare. CMF itself reads neither.

**Wrapper order.** `modcmfadapterinkandiron_cmf.ws` sorts after `inkironui_map.ws`, so its `UpdateInputFeedback` wrapper runs around Ink and Iron's.

## Dependencies

- **Ink and Iron 0.8.8, the version the adapter targets.** 0.8.7 has the same map file and the same scripts the adapter calls, so it works there too (Kyle plays 0.8.7). Recheck `InkGatherHints`, `iaiLv` and `iaiDiff` against each new Ink and Iron version.
- **modInkAndIronUI, a compile dependency.** The adapter calls `InkGatherHints`, so the scripts fail to compile without it. Install and remove the two together; remove the adapter first.
- **When Ink and Iron ships its own CMF support, uninstall this adapter.** With both installed, the game stops at the script compile screen (both add `OnCMFMapHintsReady` to `CR4MapMenu`); removing the adapter fixes it. This is accepted.
- **CMF 9 (CMF 1.3.0) to compile, from adapter 1.2.0:** `CMFRegisterChoiceOnly`, `CMFRegisterWorldPainting`, `CMFRegisterWorldCrest` (and CMF 8's `CMFSetProviderName`). Earlier CMF versions stop at the compile screen; players on them keep adapter 1.1.0.
- **CMF 5.** `CMFStylePart`, `CMFDraw`, `CMFDrawSet` and `CMFPropertyLabelColor` do not exist before CMF 5.
- **CMF 6 for the movement.** CMF 5 stores the `navigation` keys but its map does not act on them; CMF 6's map does, and adds `zoomTimed`, `padHoldMs` and `frameRate`.

## Files

| Path | What |
|---|---|
| `modCMFAdapterInkAndIron/content/scripts/local/modcmfadapterinkandiron_cmf.ws` | the hook, the hint relay, the event and the look |
| `modCMFAdapterInkAndIron/content/scripts/local/modcmfadapterinkandiron_buttons.ws` | the 143 button pictures' registrations |
| `modCMFAdapterInkAndIron/art/world/*.png` | Ink and Iron's World Map art (painting and seven crests), with WinterElfeas's permission |
| `modCMFAdapterInkAndIron/art/buttons/*.png` | Ink and Iron's gold controller buttons from the All In One, with WinterElfeas's permission |
| `modCMFAdapterInkAndIron/README.txt` | for players |
| `tools/cmf_ink_and_iron_art.py` | cuts the art from Ink and Iron's Nexus downloads (`world` from the World Map zip; `buttons` from the All In One) |
| `tests/test_cmf_ink_and_iron_adapter.py` | static checks: annotations, provider, the level tag's text and colours, every part style and drawing against Ink and Iron 0.8.7's values, the frames' 28-ring formula, the world overview art and its choice-only calls, the button pictures, the pack tool in adapter mode. Ink and Iron's names are checked when its scripts are available (`CMF_INK_SCRIPTS`) |

Build: `python tools/cmf_pack.py build source/adapters/ink-and-iron/modCMFAdapterInkAndIron --adapts modInkAndIronUI --out <new folder>` (cooks `art/world/` and `art/buttons/` into the adapter's `content/texture.cache`).

## Status

Adapter 1.2.1 (2026-10-24) adds Ink and Iron's larger clear area round the cursor for a long info box (`MapMenu.inkTipPlace`, read from the 0.8.10 and 0.9.0 code; the separate-files setup read 2026-10-24), each key behind `CMFHasAbility`, so it still compiles and runs on CMF 9 and 10; it passed its launch on 2026-10-24 (revision 11 launch, start D).

Adapter 1.2.0 (world overview and button art) passed its launch on CMF 1.3.0 on 2026-10-23 (revision 9 launch, start C, in `source/probes/rev9_launch/README.md`): the engraved overview and crests when picked, and the gold buttons, which were seen only through a test copy of CMF's map that shows controller buttons while the mouse is used, so not yet with a real controller.

The look passed its launch on CMF 5. The movement (version 0.3) has static checks only: not yet compiled or run in game. Its launch is staged in a launch record kept in the private development repository. `frameRate` is the one unproven CMF key: if that launch logs `frameRate asked=60 now=24`, the game ignores it and CMF withdraws the key; the adapter's next revision then sends `tweenEveryFrame` 1 in its place (smooth map movement research, section 7.4), and only the speed of the map's small looping animations would differ from Ink and Iron's own map. The controller crosshair keys cannot be checked without a controller.

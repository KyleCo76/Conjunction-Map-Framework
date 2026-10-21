# Ink and Iron adapter

`modCMFAdapterInkAndIron` is a separate mod that sits between Conjunction Map Framework (CMF) and Ink and Iron AIO (0.8.7 and 0.8.8 read; its `modInkAndIronUI` folder). With CMF installed, CMF's world map replaces Ink and Iron's map, while Ink and Iron's HUD, compass and menus load as normal. This adapter brings back what Ink and Iron's map adds, through CMF's general calls:
- its look (CMF 5's `CMFStylePart`, `CMFDraw` and `CMFDrawSet`);
- its quest-level tags (`OnPinReady`, `CMFStylePinLabel`, property 17 `LabelColor`);
- its key-hint row (`cmf.map.hints`);
- its map movement: panning and zoom stepped by the time since the last drawn frame, and its 60 frames a second (CMF 6's `navigation` keys).

It is written as the code Ink and Iron's author would add upstream. [`docs/authors/ink-and-iron-adapter.md`](../../../docs/authors/ink-and-iron-adapter.md) is that guide. The design is a design note kept in the private development repository section 5. Every value, with the movie member it was read from, is in a launch record kept in the private development repository.

## Provenance

These parts of Ink and Iron were read only, for its interface and its look's values:
- `inkironui_map.ws`, lines 1-107: the hint row;
- `inkironui_questlevel.ws`, lines 104-105;
- its 0.8.7 map file `panel_worldmap.redswf`, decompiled with the pinned FFDec: `MapMenu.ink*`, `iiFrame`, `HubMapContainer.inkEdge`/`inkLim`, `TooltipMap.inkFont`, `InputFeedbackButton.inkSyncCap`, `KeyboardButtonIcon.label`, `HubMapPinCategoryItemRenderer`, `StaticMapPinDescribed.iaiLvTab`, and the `HubMap`/`UniverseMap` navigation;
- its 0.8.8 map file (the same `panel_worldmap.redswf`), read for the movement by the smooth map movement research (a launch record kept in the private development repository, sections 4.1 and 6.1): `HubMap` `Timer(1)` and `handleScrollAndZoomTimer` (pan scaled by elapsed / 17 ms, cap 100 ms; zoom once per 17 ms through an accumulator), `UniverseMap` (elapsed / 24 ms), and the movie's frame rate 60.

The adapter copies no code and no art. The look is numbers (colours, sizes, positions, fonts) handed to CMF's own drawing, and the hint gathering repeats the three calls of Ink and Iron's `InkMapHints` with Ink and Iron's own `InkGatherHints`.

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
| The movement | `InkAdapterLookNavigation`, in the same wrapper | CMF 5's `frameTimed` 1, `stepMs` 17, `worldStepMs` 24, `maxStepMs` 100 and the controller crosshair keys; from CMF 6, each behind `CMFHasAbility('navigation', key)`, `zoomTimed` 0, `padHoldMs` 0 and `frameRate` 60 |

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
- **CMF 5.** `CMFStylePart`, `CMFDraw`, `CMFDrawSet` and `CMFPropertyLabelColor` do not exist before CMF 5.
- **CMF 6 for the movement.** CMF 5 stores the `navigation` keys but its map does not act on them; CMF 6's map does, and adds `zoomTimed`, `padHoldMs` and `frameRate`.

## Files

| Path | What |
|---|---|
| `modCMFAdapterInkAndIron/content/scripts/local/modcmfadapterinkandiron_cmf.ws` | the hook, the hint relay, the event and the look |
| `modCMFAdapterInkAndIron/README.txt` | for players |
| `tests/test_cmf_ink_and_iron_adapter.py` | static checks: annotations, provider, the level tag's text and colours, every part style and drawing against Ink and Iron 0.8.7's values, the frames' 28-ring formula, no art, the pack tool in adapter mode. Ink and Iron's names are checked when its scripts are available (`CMF_INK_SCRIPTS`) |

Build: copy the folder. `tools/cmf_pack.py check modCMFAdapterInkAndIron --adapts modInkAndIronUI` reports no errors or warnings against CMF 5.

## Status

The look passed its launch on CMF 5. The movement (version 0.3) has static checks only: not yet compiled or run in game. Its launch is staged in a launch record kept in the private development repository. `frameRate` is the one unproven CMF key: if that launch logs `frameRate asked=60 now=24`, the game ignores it and CMF withdraws the key; the adapter's next revision then sends `tweenEveryFrame` 1 in its place (smooth map movement research, section 7.4), and only the speed of the map's small looping animations would differ from Ink and Iron's own map. The controller crosshair keys cannot be checked without a controller.

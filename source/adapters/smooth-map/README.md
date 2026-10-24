# Smooth Map adapter

> [!NOTE]
> **Proof-of-concept example, not a shipped adapter.** This adapter is not part of any CMF release and is not on Nexus. It is published here only as a worked example for Smooth Map's author. Its keys ran in game together with Ink & Iron, which won the movement keys it also sets; Smooth Map's values on their own, without Ink & Iron, have not been checked in a launch.

`modCMFAdapterSmoothMap` is a separate mod that sits between Conjunction Map Framework (CMF) and Smooth Map 1.1 (Nexus 13530). Smooth Map has no script: all of it is its own copy of the world map file, and only one copy loads. CMF's sorts first, so under CMF Smooth Map's timing is lost. The adapter sends Smooth Map's values as CMF's general `navigation` and `opening` keys (API version 6), the way Smooth Map's author would when porting. It is the worked example of an adapter for a mod that changes only how the map moves and opens. The author-facing version is [`docs/authors/smooth-map-adapter.md`](../../../docs/authors/smooth-map-adapter.md).

It is not released: it stays here as the guide for Smooth Map's author until a port exists. From CMF 1.5.0 it also tells CMF that Smooth Map is installed (property 38); ship that inside Smooth Map's own folder, because a separate adapter folder cannot tell whether Smooth Map is installed.

## Provenance

The values come from a read-only decompile of Smooth Map 1.1's map file (the full record is kept in the private development repository; the section numbers below refer to it). The adapter copies no code, art or file from Smooth Map; it carries only the timing constants.

| What Smooth Map's map file does | Where (record 4.3) | CMF key and value |
|---|---|---|
| Region map step timer `Timer(1)`; pan by elapsed / 17 ms | `HubMap` 286, 1574-1588 | `navigation` `frameTimed` 1, `stepMs` 17 |
| World view `Timer(1)`; scroll by elapsed / 24 ms | `UniverseMap` 88, 233 | `worldStepMs` 24 |
| Elapsed time capped at 100 ms | `HubMap` 1574-1588, `UniverseMap` 233 | `maxStepMs` 100 |
| Key and stick zoom as a power of elapsed time (`_smZoomScale`) | `HubMap` | `zoomTimed` 1 |
| Each stick reading used once (no hold window) | `HubMap` | `padHoldMs` 0 |
| `Timer(1)` in `GTween.staticInit`: tweens every drawn frame; movie stays 24 fps | `GTween` 160 | `tweenEveryFrame` 1 (no `frameRate`) |
| Pins prepared during the slide-in on a 1 ms timer | `HubMap` 2332, 2350 | `opening` `pinsDuringSlide` 1, `pinStepMs` 1 |
| As many pins per tick as fit in 8 ms (batch cap 30 000) | `HubMap` 1484 | `pinBatch` 0, `pinBudgetMs` 8 |
| Show delay 1 ms; fades 0.2 s (gradient and pins) and 0.2 s (tiles) | `HubMap` | `showDelayMs` 1, `fadeSeconds` 0.2, `tileFadeSeconds` 0.2 |
| Crosshair, edge pointers, legend and tracker fade in over 0.2 s | `PinPointersManager`, `HubMap` 2328-2398, `MapMenu` 1541-1590 | `revealSeconds` 0.2 |

**Not sent**, because Smooth Map leaves them as the game's: the menu's slide-in and close (`slideSeconds`, `slideOffset`, `closeSeconds`; `CoreMenu` untouched), the movie frame rate (`frameRate`; 24 fps), the zoom limit (`zoomOutFit`, `edgeOvershoot`) and the controller crosshair keys.

**Panel-side parts with no key of their own.** Smooth Map's `HubMapContainer.smSlideOffset` (which tiles and pins count as visible while the menu slides) and its snap fix (a snap removes only its own tween, so a snap during the fade-in cannot freeze pins half-faded) are carried out by CMF's map whenever `pinsDuringSlide` or any `opening` key is set (record 7.1); the adapter needs nothing for them.

## How it works

One `@wrapMethod(CR4Game) OnGameStarted` that, after `CMFRequireVersion("modSmoothMap", 6)`, declares `modSmoothMap` with guarded generic property 38 when supported, then calls `CMFStylePart("modSmoothMap", part, key, "", value)` once for each of the 15 keys above. CMF keeps them for the game session and hands them to its map at each opening. Smooth Map has no setting, so nothing is withdrawn (`"unset"` is never sent).

**Provider and order.** Every key names `modSmoothMap`, Smooth Map's own folder, as its provider (the adapter identity rule, author guide section 12). `navigation` and `opening` keys are won key by key by the earliest folder. `mod000CommunityPatch_WorldMap`, `modInkAndIronUI` and `modMapQuestInsight` sort before `modSmoothMap`, so where they set a key they win it, and Smooth Map's other keys still apply (record 5.3, worked example: with all four installed and Map Quest Insight's "Faster map" on, Smooth Map wins `pinBudgetMs` 8 and `revealSeconds` 0.2).

**Wrapper order.** It wraps only `CR4Game.OnGameStarted` and calls no other mod, so its file name needs no `zz_`.

**Log.** Once per game session: `CMF adapter provider=modSmoothMap keys=15 accepted=<n>` (`keys=17` from CMF API version 10, which adds `readyAtFadeStart` and `revealEase`); CMF logs each refused key as `theme rejected provider=modSmoothMap ...`. The map's own lines per opening (`nav ...`, `opening ms=...`) name each key's winner.

## Dependencies

- **CMF API version 6** for any effect. Before API version 5 the file does not compile (`CMFStylePart`, `CMFRequireVersion` with the theme); with API version 5 it logs `version provider=modSmoothMap needs=6 have=5` and sends nothing.
- **Smooth Map 1.1: not a compile dependency.** Smooth Map has no script, so this template compiles without it. Its provider declaration is valid only when shipped inside Smooth Map's own folder; a separate adapter cannot establish that Smooth Map is installed.
- **Smooth Map's own CMF support.** When Smooth Map ships its own CMF support, the player uninstalls this adapter. With both installed the game may stop at the script compile screen (a support folder copied from this script defines the same functions); that is accepted, and removing the adapter fixes it (author guide section 11).
- **Version.** It targets Smooth Map 1.1, the version the research record read; other versions are not checked.
- **Saves.** The adapter writes nothing into saves.

## Files

| Path | What |
|---|---|
| `modCMFAdapterSmoothMap/content/scripts/local/modcmfadaptersmoothmap_cmf.ws` | the wrapper, the 15 keys and the log line |
| `modCMFAdapterSmoothMap/README.txt` | for players |
| `tests/test_cmf_smooth_map_adapter.py` | static checks: exactly Smooth Map's column of keys and values, every key one CMF 6 takes and in range, one provider `modSmoothMap`, the version guard, no wrapper on another mod, WitcherScript hygiene, the pack tool clean |

No art, so there is no `texture.cache`. Author fixture: copy the script into `Mods/modSmoothMap/content/scripts/local/`; do not distribute a separate declaring adapter. `tools/cmf_pack.py check modCMFAdapterSmoothMap --adapts modSmoothMap` reports no errors and no warnings.

## Status

Compiled and loaded in game in launch P6+C (2026-10-20 18:25-18:29Z; the launch record is kept in the private development repository), with Ink & Iron, Map Quest Insight 1.6.1, Community Patch and their adapters: the log shows `CMF adapter provider=modSmoothMap keys=15 accepted=15`, and with Map Quest Insight's Faster map off the map opened as Smooth Map's does (slide kept, markers ready on arrival, crosshair, legend and tracker fading in), which Kyle confirmed. In that set Ink & Iron won the movement keys it sets, so Smooth Map's own movement alone (Smooth Map without Ink & Iron) has not been checked in a launch. The adapter was left out of CMF 1.0.0 and stays a proof-of-concept example.

## Limits

- Windows only; Proton not checked.
- `padHoldMs` and stick zoom act only with a controller, which no launch has used; they are checked by value only.
- Smooth Map's folder name is exactly `modSmoothMap`, at the archive's root (checked against the archive at staging for launch P6+C).

# Witcher's Path adapter

`modCMFAdapterWitchersPath` is a separate mod that sits between Conjunction Map Framework (CMF) and Witcher's Path 1.0.3 (Nexus 13423). Witcher's Path records where Geralt travels and draws it on the world map: a route line, its own last filter tab "WITCHER'S PATH" on which only Geralt shows, and four boxes above the filter selector (from the selector up: "Erase path", the distances, the "Single color" switch and the colour legend). All of that drawing lives in its own map file, which does not load while CMF is installed, so under CMF none of it shows while the recorder keeps recording. The adapter brings it back through CMF's drawing on the map itself (API version 6: the `mapSpace` anchor, the `line` and `text` kinds, `listen`, `tab`/`tabLabel`, `above`, hover keys, `click`, `CMFDrawSetList`, `CMFMapRefresh` and the `CMFCore.OnDrawingClicked` hook). Witcher's Path is unchanged. The adapter adds no feature of its own and ships no art. The needs it was built against are a launch record kept in the private development repository (D1 to D7); the author-facing version is [`docs/authors/witchers-path-adapter.md`](../../../docs/authors/witchers-path-adapter.md).

## Provenance

Witcher's Path's interface was read on 2026-10-20 from its own 1.0.3 scripts and strings, read only, in Kyle's reference archive `source/compatability-candidates/Witcher's Path (5.01) 13423 1.0.3 2026-10-12T19-53Z CvjFPsr7Z.zip` (SHA-256 `0615f2aa21d78d910a22cfb32fcd5617a9cb724e25a711a2719bcad5fec56b6d`), unpacked only in a temporary folder of this session and not copied anywhere. The look comes from the map drawing research, a launch record kept in the private development repository section 3, checked after launch D3 against the bytecode of its map file's `MapMenu` (`updateWitchersPathUi`, `wpMakeText`, `wpDrawPanel`, `wpPanelHeight`, `wpLegendItem` and its `WP_` constants), read only in the same temporary folder; nothing copied. That reading corrected four things the research had left out or got wrong: the stack order, the 22 size of the words, the 38 px floor on every box, and the hover colour `0xE8B85C` with its outline at 0.9.

What the adapter relies on:

| Witcher's Path | Where | Used for |
|---|---|---|
| storage key `worldmap.witcherspath`: lists `xs`, `ys` (world metres), `starts`, `modes`; texts `regionText`, `totalText` | `modWitchersPathMap.ws`, `WitchersPathSend` | the route line and the distance box read it (`listen`) |
| `event OnWitchersPathClearRequest()` on `CR4MapMenu` | `modWitchersPathMap.ws` | "Erase path" (its popup, erase and redraw; a notification when the region has no route) |
| `event OnWitchersPathUseGeneralColor(useGeneral : bool)` on `CR4MapMenu` | `modWitchersPathMap.ws` | "Single color" (it stores the choice in the save) |
| `CWitchersPathData.useGeneralColor`, saved, on `GetWitcherPlayer().witchersPathData` | `modWitchersPath.ws` | the switch's state, read as its `WitchersPathSendConfig` reads it |
| `WitchersPathEnsureConfigDefaults()`, `WitchersPathGetVar(varName)`, `WitchersPathGetInt(varName, fallback)`, `WitchersPathPaletteRGB(index)`, `WitchersPathLoc(key, fallback)` | `modWitchersPathConfig.ws` | its options and texts |
| options `WPEnabled` (on unless `false` or `0`), `WPThickness` (default 4), `WPColorGeneral`, `WPColorFoot`, `WPColorHorse`, `WPColorBoat` (palette numbers, defaults 2, 2, 0, 1: green, green, red, blue) in group `WitchersPath` | `modWitchersPathConfig.ws`, `WitchersPathSendConfig` | line width and colours, switching the drawings off |
| `enum EWitchersPathMode { WPM_Foot, WPM_Horse, WPM_Boat }` | `modWitchersPathConfig.ws` | the order of the `colors` list (0, 1, 2) |
| text keys `wp_erase_path`, `wp_single_color_on`, `wp_single_color_off`, `wp_mode_foot`, `wp_mode_horse`, `wp_mode_boat` with its English fallbacks; the tab name is the literal `Witcher's Path` in its map file (no text key) | `WitchersPathSendConfig`, its `en.w3strings`, its map file | `WpAdapterLabel` |
| line 0.9 opaque, round ends, same px width at every zoom, one colour per segment's mode; boxes as wide as the filter selector (`mcHubMapPinCategoryButton`), stacked upward 6 px apart from it (erase, distances, switch, legend on top), black 0.6 with a 1 px `0x5A5A5A` outline at 0.6, each `max(38, words + 2 × 6)` px high, white words centred in the tab name's font at size 22, the legend's three words four spaces apart; the two buttons turn their outline `0xE8B85C` at 0.9, their words `0xE8B85C` and the fill 0.8 under the pointer | its map file, `MapMenu` (`WP_BTN_HEIGHT` 38, `WP_GAP` 6, `WP_PAD_Y` 6, `WP_TEXT_COLOR` `0xFFFFFF`, `WP_HOVER_COLOR` `0xE8B85C`) | the drawings' keys |

Its map file lets a line too long for its box run past both edges, and so does CMF's text box since #46.

## How it works

| Step | Who |
|---|---|
| At game start and before each map opening, the adapter asks CMF for version 6 and the drawing abilities, reads Witcher's Path's options and its saved switch through its own functions and describes the route, the four boxes and the tab; with "Enable Witcher's Path" off it withdraws everything (`CMFReleaseProvider`) | adapter |
| Witcher's Path sends the shown region's route and distances to `worldmap.witcherspath`, as without CMF | Witcher's Path, unchanged |
| CMF's map listens to that key for the route line and the distance box, and redraws both whenever a new value arrives (a region change, an erase) | CMF panel |
| Witcher's Path's first send comes inside the game's `OnConfigUI`, before CMF's map listens, and never arrives (launch D1). When the map starts listening, CMF calls `CMFCore.OnMapListening(menu, keys)`; with `worldmap.witcherspath` among the keys the adapter calls Witcher's Path's own `menu.WitchersPathSend(true)` | CMF core, adapter |
| The tab `WitchersPath` is added last because the drawings name it and no pin makes it; while it is selected the map shows only Geralt and these drawings | CMF panel |
| A click on "Erase path" or "Single color" reaches `CMFCore.OnDrawingClicked` with value 1 or 2 | CMF panel and core |
| Value 1: `menu.OnWitchersPathClearRequest()`. Value 2: `menu.OnWitchersPathUseGeneralColor(!current)`, describe the drawings again for the new state, `CMFMapRefresh()` (tab, pan and zoom stay) | adapter |
| The popup, the erase, the saved choice, the redraw after an erase | Witcher's Path, unchanged |

**Drawings.** `witchersPathRoute` (`line` on `mapSpace`, layer `under`, order 10, `view` `region`, `tab` `WitchersPath`, `listen` `worldmap.witcherspath`, `strokeWidth` = its thickness, `strokeAlpha` 0.9, `strokeZoom` 0, `colors` = foot, horse, boat, or the general colour three times, `stroke` = the general colour); and four `text` boxes, each `above` 6 the one below it at `widthShare` 1, `size` 22 and `minHeight` 38: `witchersPathErase` on `legendTab` (`click` 1), `witchersPathDistance` (`listen` with `listenFields` `text=regionText|totalText`), `witchersPathSingle` (`click` 2), and on top `witchersPathLegend`, withdrawn while single colour is on, so the other three never move.

**Claim order (documented rule).** Every drawing uses `modWitchersPath`, the mod's own folder, as provider, so folder order is the same with CMF as without it and as after a native port. An id belongs to the earliest folder that made it; another folder's calls on it are refused and logged. In map space, lower `order` draws first, then the earlier folder is on top: the route's order 10 keeps it above a map-space drawing left at 0 (a future Fog of War port) whatever the folders. The boxes share `legendTab` with any theme and show only on the Witcher's Path tab. Clicks on a drawing go only to its owner, so they never meet pin clicks.

**Wrapper order.** Not relevant. The adapter wraps `CR4Game.OnGameStarted`, `CR4MapMenu.OnConfigUI`, `CMFCore.OnMapListening` and `CMFCore.OnDrawingClicked`; Witcher's Path wraps none of them (it wraps `SwitchToHubMap` and `AddStartingSchematics`), the click wrapper tests its own provider and the listening wrapper its own key. The script file name needs no `zz_`. The adapter adds no field: the switch's state stays in Witcher's Path's save data.

## Dependencies

- **Witcher's Path 1.0.3, a compile dependency.** The adapter calls its functions and events, so the scripts fail to compile without it. Install and remove the two together, the adapter first.
- **CMF API version 6 with map-space drawing** (`CMFHasAbility('mapSpace', '')`): the adapter wraps `CMFCore.OnDrawingClicked` and calls `CMFDrawSetList` and `CMFMapRefresh`, so it does not compile on earlier versions. The drawing layer is on `feature/1.0.0-cmf-foundation` since #43 (9cb8f5c).
- **Witcher's Path's own CMF support replaces the adapter.** The adapter targets 1.0.3, which has none. When Witcher's Path ships its own, the player uninstalls the adapter; a compile error with both installed is accepted (guide section 11), and the player README and author page say so.
- **Saves.** The adapter writes nothing into saves itself. The routes and the "Single color" choice are Witcher's Path's own save data (`witchersPathData`), changed only by Witcher's Path's own events, as without CMF.

## Files

| Path | What |
|---|---|
| `modCMFAdapterWitchersPath/content/scripts/local/modcmfadapterwitcherspath_cmf.ws` | the drawings (`OnGameStarted` and `OnConfigUI` wrappers), the second send (`OnMapListening` wrapper) and the click hook (`OnDrawingClicked` wrapper) |
| `modCMFAdapterWitchersPath/README.txt` | for players |
| `tests/test_cmf_witchers_path_adapter.py` | static checks: drawing ids, kinds and anchors, every key CMF takes for its kind, the route's and distances' `listen`, the box look and buttons, the abilities asked, the hook's provider test and its two calls, Witcher's Path's options, defaults, text keys and saved switch, the only Witcher's Path names called, wrapped methods and no added field, pack check and build, WitcherScript hygiene |

No art, so there is no `texture.cache`. Build: copy the folder, or `tools/cmf_pack.py build modCMFAdapterWitchersPath --adapts modWitchersPath --out <folder>`. `tools/cmf_pack.py check ... --adapts modWitchersPath` reports no errors and no warnings, and notes that the pack needs CMF 6.

## Status

Run in game on 2026-10-20 with Witcher's Path 1.0.3, mouse and keyboard, on the I&I theme. Records: a launch record kept in the private development repository and `-4/README.md`; the pack and its steps are staged at a launch record kept in the private development repository.

- Launch D1 showed that a value written before CMF's map listens never arrives. CMF added the general hook `CMFCore.OnMapListening` (PR #43), and the adapter's wrapper of it asks Witcher's Path to send the route again. Launch D3's log shows `listen ready keys=worldmap.witcherspath|...` followed by `listen arrived key=worldmap.witcherspath`.
- Launch D3 first stopped at the script compile: `single` is a WitcherScript keyword. The parameter is now `singleColor`, and the tests check every name against the keywords.
- Launch D3 passed: with Witcher's Path turned off in its settings, nothing shows (`released provider=modWitchersPath`). Turned on, the tab, the route in the player's colours and its width at every zoom all show, "Single color" switches the colours and withdraws the legend (`drawing click ... value=2`), "Erase path" opens Witcher's Path's question and No keeps the route (`value=1`), and a normal tab brings the pins back.
- Launch D3 showed two box texts cut at the edge. Witcher's Path's map file was then read for its box layout (see Provenance), and launch D4 showed the boxes in its order, at least 38 px high, with the legend coming and going without moving the others.
- CMF's panel follow-up (#46, launches D5 and D6): a one-line box text wider than its box now runs past both edges, centred, as in Witcher's Path's own map, so every word shows; boxes stacked on the filter selector clear the I&I tab frame ("Erase path" sits above it); the hover words go back to white when the pointer leaves.

## Limits

- Witcher's Path's `perf` setting has no effect under CMF (it is speed, not look); CMF draws the line its own way and does not simplify long lines by zoom in this version.
- The tab sits after other mods' CMF tabs, and CMF's map never reopens on a CMF tab.
- Mouse only, as Witcher's Path's buttons. Windows only; Proton not checked.

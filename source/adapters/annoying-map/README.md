# Annoying Map adapter

`modCMFAdapterAnnoyingMap` is a separate mod that sits between Conjunction Map Framework (CMF) and Annoying Map 3.1 for Remastered 5.01 (Nexus 6140, by crthdr, folder `modAnnoyingMap`). It brings back the one Annoying Map feature that breaks under CMF: the map remembers where the player left it, and at what zoom, per region. It uses CMF's map view report (`CMFCore.OnMapView`), its opening hook (`CMFCore.OnMapOpening`) and its opening view call (`CMFSetOpeningView`), all API revision 9 (design `plans/2026-10-22-cmf-world-overview-pictures.md` sections 11 and 12, in the project's shared folder).

Annoying Map is unchanged. The adapter adds no rule of its own. Its other features (Geralt's marker, Roach and the boat only at signposts, herbs never) are done in Annoying Map's own `mapMenu.ws` and already work beside CMF (research `research/2026-10-23-annoying-map-abilities-gap.md`, section 3), so the adapter leaves them alone.

## Why it is needed

| Annoying Map on its own | Under CMF without the adapter |
|---|---|
| Its map file (All Quest Objectives' map file plus three reports) sends `OnPositionChanged(x, y)` on every pan step (the map container's `x`, `y`) and `OnZoomChanged(scaleX, scaleY)` on every zoom; its `mapMenu.ws` stores them per region in the save (`AMap()`, `AMapZoom()`, keyed by `AM_FilterArea(m_shownArea)`) | CMF's map file is the one that loads and sends neither report, so nothing new is stored |
| `UpdateDefaultPosition` sends the stored place through `m_fxSetDefaultPosition` | still works (the game's own default-position call, which CMF's map keeps) |
| `UpdateMapSettings` keeps the real zoom limits in `am_minZoom` .. `am_zoom34`, then `AM_InitZoom` sets the lowest and highest zoom to the stored zoom, so the map opens at it; its map file sends `OnZoomMap` on every zoom input, which re-sends the real limits | nothing sends `OnZoomMap`, so a region with a stored zoom stays at that zoom (read from code, not launched) |

## How it works

| CMF hook or call | What the adapter does |
|---|---|
| `OnMapView(menu, area, x, y, worldX, worldY, zoom, reason)` (reason `still`, `region` or `close`) | `AMap().SetXY(x, y, AM_FilterArea(area))` and `AMapZoom().SetXY(zoom, zoom, AM_FilterArea(area))`: exactly what Annoying Map's own `OnPositionChanged` and `OnZoomChanged` store (its `AM_InitZoom` reads only the first number). It writes under the report's own area, so a report made while switching region lands on the region it describes |
| `OnMapOpening(menu, area, mapContext)` (every region shown: opening and region switch) | when `menu.am_maxZoom > 0` (Annoying Map's `UpdateMapSettings` has run), `menu.OnZoomMap()`: Annoying Map's own event re-sends the real limits. Then `CMFSetOpeningView("modAnnoyingMap", area, 0, 0, savedZoom, true)`: the stored zoom (0 = none, the game's zoom) inside the real limits; `keepPlace` because Annoying Map already sent the place |
| `OnGameStarted` | `CMFSetProviderName("modAnnoyingMap", "Annoying Map")`, its name on the menu add-on's Opening view row |

The contract the main thread was asked to confirm for revision 9 (units of `x`, `y`, `zoom`; when `OnMapOpening` fires; that the panel applies the opening view after the script's `SetMapZooms`; that nothing fires without CMF's map) is in `probes/2026-10-23-cmf-annoying-map/CONTRACT-for-main.md`.

**Provider and order.** Every call names `modAnnoyingMap`, Annoying Map's own folder. The opening view is won per area by the earliest folder (the movement rule), through the menu add-on's `Movement_View` piece. With Vanilla there, Annoying Map's stored place still applies (its own script), and the zoom is the game's; the real limits are back either way.

**Speed.** Nothing runs per frame. One write per report (when the map stops, switches region or closes) and one call per region shown.

## Log

- First eight stored views of a session: `CMF adapter provider=modAnnoyingMap kept area=<area> reason=<still|region|close> x=<x> y=<y> zoom=<zoom>`.
- Each region shown: `CMF adapter provider=modAnnoyingMap open area=<area> context=<FastTravel|Boat|GlobalMap> zoom=<stored zoom or 0> limits=<restored|notready>`. `notready` means Annoying Map's script had not sent its limits yet (the contract says this must not happen).

## Provenance

Read on 2026-10-23 from Kyle's download `Annoying Map (Remastered 5.01) 6140 3.1 2026-10-09T01-35Z KA0dHIkdz.zip` (`source\compatability-candidates`), copied read-only for this thread into `research/2026-10-23-annoying-map-source/` with the decompiled map-file lines that send the three reports. Nothing is copied into the adapter.

| File | Lines | SHA-256 |
|---|---|---|
| `scripts/local/amap.ws` | 74 | `84681432589ff0b9ae201c8e09d83ab080f565868c3d9fd92d0bc940df8480c8` |
| `scripts/local/amap_anno.ws` | 21 | `01e445070e8b404315c36343d4cd6c75f4eacc76da23afeb03c61049752735cc` |
| `scripts/game/gui/menus/mapMenu.ws` | 2284 (Annoying Map's edits: 339, 1034, 2017, 2020, 2060) | `00930173b4a25a7a624ff10c606cbd5a63737d1dd1cecd768b0107fc1e39a4cf` |

| Name | Where | Used for |
|---|---|---|
| `AMap() : AM_XYs`, `AMapZoom() : AM_XYs` | `amap.ws` 2, 6 (global; saved fields on `CR4Player`, `amap_anno.ws`) | the stored place and zoom |
| `AM_XYs.SetXY(x, y, area)`, `GetXY(area) : AM_XY`, `AM_XY.GetX()` | `amap.ws` | write and read one region's entry |
| `AM_FilterArea(area) : name` | `amap.ws` | Velen and Novigrad share `AN_NMLandNovigrad` |
| `event OnZoomMap()`, `var am_maxZoom` on `CR4MapMenu` | `mapMenu.ws` 2020 | re-send the real zoom limits |

## Dependencies

- **Annoying Map 3.1, a compile dependency.** The adapter calls its functions and its `CR4MapMenu` event. It is installed and removed together with that mod, and removed first.
- **CMF 1.3.0 (API revision 9)** to compile (`OnMapView`, `OnMapOpening`, `CMFSetOpeningView`). Earlier CMF versions stop at the compile screen.
- **Load order.** CMF before Annoying Map (CMF's `mod0000_` folder sorts first). Annoying Map's own map file then does not load.
- **Saves.** The adapter adds nothing to saves; Annoying Map's own fields hold the views, as before.

## Files

| Path | What |
|---|---|
| `modCMFAdapterAnnoyingMap/content/scripts/local/modcmfadapterannoyingmap_cmf.ws` | the three wrappers |
| `modCMFAdapterAnnoyingMap/README.txt` | for players |
| `tests/test_cmf_annoying_map_adapter.py` | static checks |

No art, so there is no `texture.cache`. Build: copy the folder.

## Status

Launched in the revision 9 launch, start B (CMF 1.3.0 previews, record `source/probes/rev9_launch/README.md`), with Annoying Map 3.1 and without the revision 9 test packs, so only Annoying Map set opening views. It passed: the map reopened where Kyle left it, at his zoom, and both ends of the zoom range were reachable. One blurry map after switching Novigrad, Skellige, Novigrad was a CMF panel fault, fixed in 1.3.0-preview-9; the rerun's checks N1 to N4 passed (place, zoom, sharp, full zoom range). The stuck zoom it prevents is still read from code only: the launch ran with the adapter installed.
